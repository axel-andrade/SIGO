class BatchesController < ApplicationController
  helper_method :buscar_planilha
  
  def index
      @batches = Batch.all  
  end

   def download
    send_file "#{Rails.root}/public/#{params[:file_name]}"
    
  end
  
  def buscar_planilha(diretorio)
    
    @aux = diretorio.to_s

    if @aux.index(/.xls/) != nil

    	render html: @aux
        
	    planilha = Spreadsheet.open 'public'+@aux #/uploads/batch/attachment/8/endereco.xls' # Abrindo a planilha
	
	    sheet1 = planilha.worksheet 0 # Especificando uma única planilha por índice
		
		arquivo = File.new("public/resultado.csv","w")
    #arquivo.write("Logradouro            | Número       | Bairro       | Longitude        | Latitude  ")
		
    sheet1.each do |row|

        @linha = row[0].to_s() +","+ row[1].to_s() +","+row[2].to_s() #juntando as colunas do excel
        @resultado = buscarSQL(@linha.to_s()) #enviando a linda para a funcao de busca e pegando o resultado
		    arquivo.write("#{row[0]} ; #{row[1]} ; #{row[2]} ; #{@resultado}\n")

        @resultado = ""

		end
        
		arquivo.close

	else 
	    render html: "Arquivo invalido"
    end
  end 

  def new
      @batch = Batch.new
  end
   
  def create
      @batch = Batch.new(resume_params)

      if !Batch.last.blank?
         Batch.delete(Batch.last)
      end
      
      if File.exist?("public/resultado.csv")
         File.delete("public/resultado.csv")
      end

      if @batch.save
         redirect_to batches_path, notice: "The resume #{@batch.name} has been uploaded."
      else
         render "new"
      end
      
  end
   
  def destroy
      @batch = Batch.find(params[:id])
      @batch.destroy
      redirect_to root_path
      #redirect_to batches_path, notice:  "The resume #{@batch.name} has been deleted."
  end
  
  def deletar_cadastrar
      @batch = Batch.find(params[:id])
      @batch.destroy
      redirect_to new_batch_path
  end
   
  private
      def resume_params
      params.require(:batch).permit(:name, :attachment)
   end

end
