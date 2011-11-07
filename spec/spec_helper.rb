require 'rubygems'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'tvdb'
require 'spec'
require 'spec/autorun'

def load_example_data
  @series1_xml = File.read(File.dirname(__FILE__) + "/data/series1.xml")
  @series2_xml = File.read(File.dirname(__FILE__) + "/data/series2.xml")
  @series_xml = @serie1_xml + @serie2_xml
  @series1_zip = File.open(File.dirname(__FILE__) + "/data/series1.zip")
  @series1_full_xml = Zip::ZipFile.new(@serie1_zip.path).find_entry("en.xml").get_input_stream.read
  @series2_zip = File.open(File.dirname(__FILE__) + "/data/series2.zip")
  @series2_full_xml = Zip::ZipFile.new(@serie2_zip.path).find_entry("en.xml").get_input_stream.read
end