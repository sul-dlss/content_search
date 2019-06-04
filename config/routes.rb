Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: 'search#home'
  get '/:id/search', to: 'search#search', as: :iiif_content_search
  get '/:id/autocomplete', to: 'search#autocomplete', as: :iiif_autocomplete

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  mount OkComputer::Engine, at: "/status"
end
