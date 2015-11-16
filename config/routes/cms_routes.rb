Rails.application.routes.draw do


  # Make sure this routeset is defined last

  comfy_route :cms_admin, :path => '/admin'
  get 'admin/import_export', controller: 'import_exports', action: :index, as: :comfy_custom_import_export
  get '/admin/import_export/trigger_export', controller: 'import_exports', action: :export_command, as: :comfy_export
  get '/admin/import_export/trigger_import', controller: 'import_exports', action: :import_command, as: :comfy_import
  comfy_route :cms, :path => '/', :sitemap => false

end;