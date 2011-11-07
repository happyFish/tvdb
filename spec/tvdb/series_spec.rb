require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

module TVdb
  describe Series do
    before(:each) do
      load_example_data
    end
    
    it "should build from TheTVDB series xml" do
      series = Series.new(@series1_xml)
      series.seriesname = "The Big Bang Theory"
      series.firstaired = "2007-09-01"
      series.imdb_id = "tt0898266"
      series.status = "Continuing"
    end
    
    it "should map actors field to an array" do
      series = Series.new("<Series><actors>|Humphrey Bogart|</actors></Series>")
      series.actors.should == ["Humphrey Bogart"]
      
      series = Series.new("<Series><actors>|Humphrey Bogart|Ingrid Bergman|Paul Henreid|</actors></Series>")
      series.actors.should == ["Humphrey Bogart", "Ingrid Bergman", "Paul Henreid"]
    end
    
    it "should map genre field to field genres as an array" do
      series = Series.new("<Series><genre>|Comedy|</genre></Series>")
      serie.genres.should == ["Comedy"]
      
      series = Series.new("<Series><genre>|Comedy|Romance|</genre></Series>")
      serie.genres.should == ["Comedy", "Romance"]
    end
    
    it "should convert poster attribute to a TheTVDB banner url" do
      series = Series.new("<Series><poster>posters/80379-1.jpg</poster></Series>")
      serie.poster.should == TVdb::BANNER_URL % "posters/80379-1.jpg"
    end
    
    it "should parse episodes and return them as an array of Element objects" do
      series = Series.new(@serie1_full_xml)
      
      series.episodes.size.should == 55 # There are 55 <Episode> tags in the zip file
      
      series.episodes.first.tvdb_id.should == '1102131'
      series.episodes.first.episodename.should == 'Physicist To The Stars'
      series.episodes.first.seriesid.should == serie.tvdb_id
      
      series.episodes[1].tvdb_id.should == '1088021'
      series.episodes[1].episodename.should == 'Season 2 Gag Reel'
      
      series.episodes.last.tvdb_id.should == '1309961'
      series.episodes.last.episodename.should == 'The Maternal Congruence'
    end
    
  end
end