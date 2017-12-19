Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root to: 'search#search'
  get '/:id/search', to: 'search#search', as: :iiif_content_search

  # discovery dispatcher API uses subtargets; we could care less, so make them optional.
  put '/items/:druid/(*subtargets)', to: 'items#update'
  delete '/items/:druid/(*subtargets)', to: 'items#destroy'

  mount OkComputer::Engine, at: "/status"
end
