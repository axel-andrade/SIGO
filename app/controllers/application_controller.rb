class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  
  helper_method :buscarDBF
  helper_method :buscarSQL
  helper_method :pegar_ultimo
  helper_method :gerar_shapefile
  helper_method :zipar_arquivos
  
  #helper_method permita que chame alguma action selecionada na view 
  
def pegar_ultimo(tipo,opcao)

    if opcao==1
      
        @ultimoregistro = Search.last #pega ultimo registro da tabela 

        tipo.each do |search|
          if search == @ultimoregistro 
           @auxiliar = search.logradouro + "," + search.numero + "," + search.bairro
          end
        end

        return @auxiliar

    else

       @ultimoregistro = Batch.last 

       tipo.each do |batch|
          if batch == @ultimoregistro 
           @auxiliar = batch.attachment
          end
       end

       return @auxiliar 

    end 

      #render html: @auxiliar # render html: @variavel exibi na tela o conteudo da sua variavel
      
  end 

  def buscarSQL(endereco)
      

      if endereco != nil
          
          @vetor = corrigir_texto(endereco.split(","))

          con = Mysql.new('localhost', 'root', 'root', 'SIGHabitat')
          record = con.query("select logradouro,numero,bairro,longitudex,latitudey from OuroPreto 
                              where logradouro = '#{@vetor[0]}' AND numero = '#{@vetor[1]}' AND bairro = '#{@vetor[2]}';")
          
  
          record.each_hash { |h| 
             
              #trocando "," por "." para gerar um shapefile posteriomente
              h['longitudex'][3] = '.'
              h['latitudey'][3] = '.'

              @resultado = h['longitudex']+ ' ; '+ h['latitudey']
          } 
          
          if !@resultado.blank? 
             return @resultado
          else 
              return "Não encontrado"
          end 

      else 
          return "Endereco nao cadastrado ou invalido"
      end
      
  end 

  def buscarDBF(endereco)
     
     puts endereco 

      if endereco != nil
          
          @vetor = corrigir_texto(endereco.split(","))
                
          encontrou = 0  #verificar se foi encontrado no banco

          enderecos = DBF::Table.new("lib/dbf/UH_nov_2012_pt.dbf")

          enderecos.find(:all,logradouro: @vetor[0], numero: @vetor[1], bairro: @vetor[2]) do |record|  #usando find com os parametros para encontrar o endereco exatos
            
              if record  #se foi encontrado o endereco return latitude e longitude pu escreve em um tabela xls
                 
                 @resultado = "Longitude : "+record.longitudex+"       Latitude: "+record.latitudey
                 encontrou = 1
                 break #se os enderecos sao todos diferentes nao ha necessidade de percorrer mais depois de encontrado
              
              end 

          end

          if encontrou == 1 #se encontrou retorna o resultado 
             return @resultado
          else 
             return  "Não encontrado."
          end 
      else 
          return "Endereco nao cadastrado ou invalido"
      end

  end

  def corrigir_texto(texto)
      
      texto.each_with_index do |campo,i|  #percorrendo o campos que serao  pesquisados 
                
        if texto[i].strip! != nil   # verificando se ha espacos em branco no inicio ou no final da string
           texto[i] = texto[i].strip
        end

        if texto[i].upcase! == nil #verificando se ja estao todas maiuscula
           texto[i] = texto[i].upcase  
        end 

      end

      #retirando strings "ruas" e "avenidas" da planilha

           if texto[0].index(/RUA /)!=nil
              texto[0].slice! "RUA "
           elsif texto[0].index(/AVENIDA /) !=nil
              texto[0].slice! "AVENIDA "
           elsif texto[0].index(/AV. /)!=nil
                   texto[0].slice! "AV. "
           end


      return texto #retornando texto editado

  end

end

# funcao para gerar a .prj file
def getWKT_PRJ (epsg_code)
  
   @wtk =  open("http://spatialreference.org/ref/epsg/#{epsg_code}/prettywkt/").read
   aux = @wtk.to_s()
   remove_spaces = aux.gsub(" ","")
   output = remove_spaces.gsub("\n", "")
   return output

end 

#funcao responsavel por gerar os arquivos shapefile
def gerar_shapefile
    
    RubyPython.start

    shapefile = RubyPython.import("shapefile")
    #criando um ponto no shapefile
    meu_shp = shapefile.Writer(shapefile.POINT)

    #Para cada registro, deve haver uma geometria correspondente.
    meu_shp.autoBalance = 1

    # create the field names and data type for each.
    meu_shp.field("logradouro", "C")
    meu_shp.field("numero", "C")
    meu_shp.field("bairro", "C")

    # Verificando se o arquivo de resultado existe
    if File.exist?("public/resultado.csv") 

        CSV.foreach("public/resultado.csv") do |row|
              
              aux = row.to_s()
              aux = aux.gsub("[","")
              aux = aux.gsub("]","")
              vetor = aux.split(";")
  
              #se o tamanho do array nao e 5 entao nao e um arquivo que vai para o shapefile pois nao contem todos os dados
              if vetor.length == 5

                logradouro = vetor[0]
                numero = vetor[1]
                bairro = vetor[2]
                latitude = vetor[3]
                longitude = vetor[4]
                

                #criando pontos geometria
                aux = meu_shp.point(longitude.to_f(),latitude.to_f())
                # adicianando atributos no dbf
                meu_shp.record(logradouro,numero,bairro)

              end

          end

          

    end

    meu_shp.save("public/shapefile/resultado")

    # criando o arquivo de projecao
    prj = open("public/shapefile/resultado.prj", "w")
    epsg = getWKT_PRJ("4326")
    prj.write(epsg)
    prj.close()

   RubyPython.stop #fechando interpretador python
   
end

def zipar_arquivos()
    
    if File.exist?("public/resultado.zip")
       File.delete("public/resultado.zip")
    end
    folder = "public/shapefile"
    input_filenames = ['resultado.dbf','resultado.shp','resultado.prj','resultado.shx']

    zipfile_name = "public/resultado.zip"

    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      input_filenames.each do |filename|
        # Two arguments:
        # - The name of the file as it will appear in the archive
        # - The original file, including the path to find it
        zipfile.add(filename, File.join(folder, filename))
      end
      zipfile.get_output_stream("myFile") { |f| f.write "myFile contains just this" }
    end
end
