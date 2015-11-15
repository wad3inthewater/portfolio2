require 'rubygems'
require 'zip'

# This handles import/exporting for Comfy the web2 cms for content pages. Check "cms_routes.rb" for the routes assoicated with this controller.
# The view that has the js for making calls is under "app/views/comfy/admin/cms/import_exports/index.html.erb"
class ImportExportsController < Comfy::Admin::Cms::BaseController
  skip_before_action :verify_authenticity_token, :only => [:export_zip, :trigger_import]
  before_action :authorize
  before_action :build_layout,  :only => [:new, :create]
  before_action :load_layout,   :only => [:edit, :update, :destroy]

  EXPORT_FOLDER = "./db/cms_fixtures/export-fixtures"
  IMPORT_FOLDER  = "./db/cms_fixtures/import-fixtures"

  def index
    render 'comfy/admin/cms/import_exports/index'
  end

  # method assoicated with route that calls make_zip and renders out the file name to be passed in jsonp
  def export_zip
    zipped_file = make_zip
    if (zipped_file)
      render :json => {'file_name' => zipped_file }, :callback => params[:callback]
    else
      redirect_to comfy_custom_import_export_path
    end
  end
  # method assoicated with route that grabs the zip file from s3 and calls the comfy import
  def trigger_import
    aws_file = retrieve_cms_content_from_s3(params[:file_name])
    File.open("auto-import.zip", "w:ASCII-8BIT") do |f|
      f.puts aws_file
    end
  import_from("./auto-import.zip")
    head :ok
  end

  private
  # Runs the comfy export and zips up the fixtures exported. Takes the newly created zip and uploads it to s3.
  def make_zip
    fixtures_zip = "./export-fixtures.zip"
    timestamp = Time.now.to_i
    if File.exist?(fixtures_zip)
      FileUtils.rm(fixtures_zip)
    end
    comfy_sites = Comfy::Cms::Site.all
    comfy_sites.each do |comfy_site|
      ComfortableMexicanSofa::Fixture::Exporter.new(comfy_site.identifier, "export-fixtures/#{comfy_site.identifier}").export!
    end
    entries = Dir.entries(EXPORT_FOLDER) - %w(. ..)
    ::Zip::File.open('./export-fixtures.zip', ::Zip::File::CREATE) do |io|
      write_entries entries, '', io
    end
    upload_comfy_fixtures_to_s3(File.open(fixtures_zip), timestamp)
    FileUtils.rm(fixtures_zip)
    FileUtils.rm_rf(EXPORT_FOLDER)
    return "comfy_fixture_upload_#{timestamp}"
  end
  # unzips the fixtures file passed in and imports it into the env using comfy
  def import_from(filepath)
    if File.exists?(IMPORT_FOLDER)
      FileUtils.rm_rf(IMPORT_FOLDER)
    else
      FileUtils.mkdir(IMPORT_FOLDER)
    end
    Zip::File.open(filepath) do |zip_file|
      zip_file.each do |entry|
        Rails.logger.debug "Extracting #{entry.name}"
        entry.extract(File.join(IMPORT_FOLDER , entry.name))
      end
    end

    comfy_sites = Comfy::Cms::Site.all
    comfy_sites.each do |comfy_site|
      ComfortableMexicanSofa::Fixture::Importer.new("/import-fixtures/#{comfy_site.identifier}", comfy_site.identifier).import!
    end
    FileUtils.rm(filepath)
    FileUtils.rm_rf(IMPORT_FOLDER)
   end

  # puts the zip file created by make_zip into the assets/cms bucket on s3
  def upload_comfy_fixtures_to_s3(zip_file, timestamp)
    aws_filename = "comfy_fixture_upload_#{timestamp}"
    s3 = RightAws::S3Interface.new(Web2::SERVICES[:cms][:aws_token], Web2::SERVICES[:cms][:aws_secret])
    headers = {
      "x-amz-acl" => "private"
    }
    result = s3.put(Web2::SERVICES[:cms][:aws_bucket], aws_filename, zip_file, headers)
    Rails.logger.info 'http://' + Web2::SERVICES[:cms][:aws_bucket] + '/' + aws_filename
    aws_filename
  end
  # puts the zip file created by make_zip into the assets/cms bucket on s3
  def retrieve_cms_content_from_s3(aws_filename)
    s3 = RightAws::S3Interface.new(Web2::SERVICES[:cms][:aws_token], Web2::SERVICES[:cms][:aws_secret])
    begin
      result = s3.get(Web2::SERVICES[:cms][:aws_bucket], aws_filename)
    rescue
      retry
    end
    result[:object]
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

  # A helper method to make the recursion work.
  def write_entries(entries, path, io)
    entries.each do |e|
      zip_file_path = path == '' ? e : File.join(path, e)
      disk_file_path = File.join(EXPORT_FOLDER, zip_file_path)
      Rails.logger.debug "Deflating #{disk_file_path}"

      if File.directory? disk_file_path
        recursively_deflate_directory(disk_file_path, io, zip_file_path)
      else
        put_into_archive(disk_file_path, io, zip_file_path)
      end
    end
  end

  def recursively_deflate_directory(disk_file_path, io, zip_file_path)
    io.mkdir zip_file_path
    subdir = Dir.entries(disk_file_path) - %w(. ..)
    write_entries subdir, zip_file_path, io
  end

  def put_into_archive(disk_file_path, io, zip_file_path)
    io.get_output_stream(zip_file_path) do |f|
      f.puts(File.open(disk_file_path, 'rb').read)
    end
  end

end
