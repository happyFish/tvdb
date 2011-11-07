require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module TVdb
  describe Client do
    before(:each) do
      @client = Client.new("api_key")
      load_example_data
    end
    
    it "should have an api_key" do
      @client.api_key.should == "api_key"
    end
    
    it "should have an Urls instance for the given api_key" do
      @client.urls.should be_an_instance_of Urls
      @client.urls[:series_xml].template.should match /^http:\/\/www\.thetvdb\.com\/api\/api_key/
    end
    
    describe "get series full data on zip" do
      it "should request the TheTVDB series zip url" do
        OpenURI.should_receive(:open_uri).with(@client.urls[:series_zip] % {:series_id => "123987", :language => "en"}).and_return(@serie1_zip)
        @client.get_series_zip("123987")
      end
      
      it "should request the TheTVDB series zip url in given language" do
        OpenURI.should_receive(:open_uri).with(@client.urls[:series_zip] % {:series_id => "123987", :language => "de"}).and_return(@serie1_zip)
        @client.get_series_zip("123987", 'de')
      end
      
      it "should avoid OpenURI::HTTPError exceptions" do
        # Trying the TheTVDB API I have experienced that search return some
        # invalid records which lead to 404 errors when requesting their info
        OpenURI.stub!(:open_uri).and_raise(OpenURI::HTTPError.new("", "a"))
        lambda {@client.get_series_zip("123987")}.should_not raise_error
        @client.get_series_zip("123987").should be_nil
      end
    end
    
    describe "search" do
      it "should request the TheTVDB search uri with given name" do
        OpenURI.should_receive(:open_uri).with(@client.urls[:get_series] % {:name => URI.escape("Best show"), :language => "en"}).and_return(@serie1_zip)
        @client.search("Best show")
      end
      
      it "should request the TheTVDB search uri with given name and language" do
        OpenURI.should_receive(:open_uri).with(@client.urls[:get_series] % {:name => URI.escape("Best show"), :language => "de"}).and_return(@serie1_zip)
        @client.search("Best show", {:lang => "de"})
      end
      
      it "should get the zips of returned results" do
        OpenURI.should_receive(:open_uri).and_return(StringIO.new(@series_xml))
        
        @client.should_receive(:get_series_zip).with("80379", "en").and_return(nil)
        @client.should_receive(:get_series_zip).with("73739", "en").and_return(nil)
        @client.search("something")
      end
      
      it "should get the info for each return result in given language" do
        OpenURI.should_receive(:open_uri).and_return(StringIO.new(@series_xml))
        
        @client.should_receive(:get_series_zip).with("80379", "de").and_return(nil)
        @client.should_receive(:get_series_zip).with("73739", "de").and_return(nil)
        @client.search("something", :lang => "de")
      end
      
      it "should return the Series corresponding to each response" do
        OpenURI.should_receive(:open_uri).and_return(StringIO.new(@series_xml))
        
        @client.should_receive(:get_series_zip).with("80379", "en").and_return(Zip::ZipFile.new(@serie1_zip.path))
        @client.should_receive(:get_series_zip).with("73739", "en").and_return(Zip::ZipFile.new(@serie2_zip.path))
        
        results = @client.search("something")
        results.size.should == 2
        results.each{|r| r.class.should == TVdb::Serie}
        results.map(&:seriesname).sort.should == ["Lost", "The Big Bang Theory"]
      end
      
      it "should give just the results with exact name" do
        OpenURI.should_receive(:open_uri).and_return(StringIO.new(<<-XML
        <Series><id>73739</id><SeriesName>Lost</SeriesName></Series>
        <Series><id>73420</id><SeriesName>Finder of Lost Loves</SeriesName></Series>
        <Series><id>98261</id><SeriesName>Lost Evidence</SeriesName></Series>
        XML
        ))
        
        @client.should_receive(:get_series_zip).once.with("73739", "en").and_return(Zip::ZipFile.new(@serie2_zip.path))
        results = @client.search("Lost", :match_mode => :exact)
        results.size.should == 1
        results.first.seriesname.should == "Lost"
      end
      
      it "should skip unreachable results" do
        OpenURI.should_receive(:open_uri).and_return(StringIO.new(@series_xml))
        
        @client.should_receive(:get_series_zip).with("80379", "en").and_return(Zip::ZipFile.new(@serie1_zip.path))
        @client.should_receive(:get_series_zip).with("73739", "en").and_return(nil)
        
        results = @client.search("something")
        results.size.should == 1
        results.first.seriesname.should == "The Big Bang Theory"
      end
    end
    
    describe "get series in other language" do
      it "should avoid empty series" do
        @client.series_in_language(Series.new(""), "es").should be_nil
      end
      
      it "should give the series itself when language is the same" do
        series = Series.new(@serie1_xml)
        @client.series_in_language(serie, "en").should == serie
      end
      
      it "should get the series with information in the given language" do        
        original = Series.new("<Series><id>4815162342</id></Series>")
        zip_mock = mock "ZipFile"
        
        @client.stub!(:get_series_zip).and_return(zip_mock)
        @client.stub!(:read_series_xml_from_zip).with(zip_mock, 'es').and_return("<Series><id>4815162342</id><Overview>¿Qué quieren decir esos números?</Overview></Series>")

        translated = @client.series_in_language(original, "es")
        translated.tvdb_id.should == "4815162342"
        translated.overview.should == "¿Qué quieren decir esos números?"
      end
      
      it "should return nil if there is no series info" do
        original = Series.new("<Series><id>4815162342</id></Series>")
        @client.should_receive(:get_series_zip).with("4815162342", "es").and_return(nil)
        @client.series_in_language(original, "es").should be_nil
      end
    end
  end
end
