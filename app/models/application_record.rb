class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
    
  def self.download_arquivo(diretorio)
		Zip::File.open(diretorio+'.zip', Zip::File::CREATE) do |arquivo_zip|
      Dir.chdir diretorio
      Dir.glob("**/*").reject { |e| File.directory?(e) }.each do |arquivo|
        puts "Adicionando #{arquivo}"
        arquivo_zip.add(arquivo.sub(diretorio + '/', ''), arquivo)
      end
		end
  end
  
end
