class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  helper_method :buscarDBF
  helper_method :buscarSQL
  helper_method :pegar_ultimo
  
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

              @resultado = h['longitudex']+ ' | '+ h['latitudey']
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
