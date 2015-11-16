require 'rubygems'

# This handles import/exporting for Comfy the web2 cms for content pages. Check "cms_routes.rb" for the routes assoicated with this controller.
# The view that has the js for making calls is under "app/views/comfy/admin/cms/import_exports/index.html.erb"
class ImportExportsController < Comfy::Admin::Cms::BaseController
  #kip_before_action :verify_authenticity_token, :only => [:export_zip, :trigger_import]
  #before_action :authorize
  before_action :build_layout,  :only => [:new, :create]
  before_action :load_layout,   :only => [:edit, :update, :destroy]

  EXPORT_FOLDER = "./db/cms_fixtures/export-fixtures"
  IMPORT_FOLDER  = "./db/cms_fixtures/import-fixtures"

  def index
    render 'comfy/admin/cms/import_exports/index'
  end

  def export_command
    comfy_sites = Comfy::Cms::Site.all
    comfy_sites.each do |comfy_site|
      ComfortableMexicanSofa::Fixture::Exporter.new(comfy_site.identifier, "#{comfy_site.identifier}").export!
    end
    redirect_to comfy_custom_import_export_path
  end
  def import_command
    comfy_sites = Comfy::Cms::Site.all
    comfy_sites.each do |comfy_site|
      ComfortableMexicanSofa::Fixture::Importer.new("portfolio", comfy_site.identifier = "portfolio").import!
    end
    redirect_to comfy_custom_import_export_path
  end

  def build_layout
    @layout = @site.layouts.new(layout_params)
    @layout.parent      ||= ::Comfy::Cms::Layout.find_by_id(params[:parent_id])
    @layout.app_layout  ||= @layout.parent.try(:app_layout)
    @layout.content     ||= '{{ cms:page:content:rich_text }}'
  end

  def load_layout
    @layout = @site.layouts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = I18n.t('comfy.admin.cms.layouts.not_found')
    redirect_to :action => :index
  end

  def layout_params
    params.fetch(:layout, {}).permit!
  end

end
