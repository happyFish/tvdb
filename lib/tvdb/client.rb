module TVdb
  class Client
    attr_reader :api_key, :urls
    
    def initialize(api_key)
      @api_key = api_key
      @urls = Urls.new(api_key)
    end
    
    def search(name, options={})
      default_options = {:lang => 'en', :match_mode => :all}
      options = default_options.merge(options)
      
      search_url = @urls[:get_series] % {:name => URI.escape(name), :language => options[:lang]}
      
      doc = Hpricot(OpenURI.open_uri(search_url).read)
      
      ids = if options[:match_mode] == :exact
        doc.search('series').select{|s| s.search('seriesname').inner_text == name }.collect{|e| e.search('id')}.map(&:inner_text)
      else
        doc.search('series').search('id').map(&:inner_text)
      end
      
      ids.map do |sid|
        get_series_from_zip(sid, options[:lang])
      end.compact
    end
    
    def series_in_language(serie, lang)
      return nil if !serie.respond_to?(:tvdb_id)
      return series if lang == serie.language
      
      get_series_from_zip(serie.tvdb_id, lang)
    end
    
    def get_series_zip(id, lang='en')
      zip_file = open_or_rescue(@urls[:series_zip] % {:series_id => id, :language => lang})
      zip_file.nil? ? nil : Zip::ZipFile.new(zip_file.path)
    end
    
    private
    
    def open_or_rescue(url)
      begin
        return OpenURI.open_uri(url)
      rescue OpenURI::HTTPError # 404 errors for some of the ids returned in search
        return nil
      end
    end
    
    def get_series_from_zip(sid, lang='en')
      zip = get_series_zip(sid, lang)
      return nil if zip.nil?
      
      xml = read_series_xml_from_zip(zip, lang)
      return xml ? Series.new(xml) : nil
    end
    
    def read_series_xml_from_zip(zip, lang='en')
      if entry = zip.find_entry("#{lang}.xml")
        entry.get_input_stream.read
      end
    end
  end
end