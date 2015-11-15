Rails.application.routes.draw do
  comfy_route :cms_admin, :path => '/admin'

  # Make sure this routeset is defined last

  get '/comfy/import_export', controller: 'import_exports', action: :index, as: :comfy_custom_import_export
  #get '/comfy/import_export/trigger_export', controller: 'import_exports', action: :export_zip, as: :comfy_export_zip
  #get '/comfy/import_export/trigger_import', controller: 'import_exports', action: :trigger_import, as: :comfy_trigger_import

  comfy_route :cms, :path => '/', :sitemap => false
end;