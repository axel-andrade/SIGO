Rails.application.routes.draw do
  
  devise_for :users, :controllers => { :omniauth_callbacks => "callbacks" }
  resources :batches, only: [:index, :new, :create, :destroy]

  get 'download'=> 'batches#download'

  get 'batches/index'

  get 'batches/new'

  get 'batches/create'

  get 'batches/destroy'

  get 'arquivos/index'
  post 'arquivos/upload_arquivo'
  post 'arquivos/download_arquivo'

  root 'welcome#index'
  resources :searches
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
