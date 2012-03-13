require 'helper/account'

require 'box/api'
require 'box/account'
require 'box/file'
require 'box/folder'

describe Box::File do
  describe "operations" do
    before(:all) do
      @root = get_root
      spec = @root.find(:name => 'rspec folder', :type => 'folder').first
      spec.delete if spec
    end

    before(:each) do
      @hello_file = 'dummy.test'
      File.open(@hello_file, 'w') { |f| f.write("Hello World!") }

      @vegetables = 'veg.test'
      File.open(@vegetables, 'w') { |f| f.write("banana, orange, avachokado") }

      @test_root = @root.create('rspec folder')
      @dummy = @test_root.upload(@hello_file)
    end

    after(:each) do
      File.delete(@hello_file)
      File.delete(@vegetables)

      @test_root.delete
    end

    it "gets file info" do
      @dummy.name.should_not == nil
    end

    it "lazy-loads file info" do
      @dummy.data['sha1'].should == nil
      @dummy.sha1.should_not == nil
      @dummy.data['sha1'].should_not == nil
    end

    it "uploads a new file" do
      @dummy.parent.should be @test_root
      @dummy.name.should == 'dummy.test'
    end
    
    it "uploads a file once by default" do
      @test_root.files.should have(1).thing
      
      @test_root.upload(@hello_file)
      @test_root.files.should have(1).thing
    end

    it "uploads a copy" do
      file = @dummy.upload_copy(@vegetables)

      file.name.should == 'dummy (1).test'
      file.parent.should be @test_root
      file.sha1.should_not == @dummy.sha1

      @test_root.files.should have(2).things
    end

    it "overwrites a file" do
      temp = @dummy.sha1
      @dummy.upload_overwrite(@vegetables)

      @dummy.parent.should be @test_root
      @dummy.name.should == 'dummy.test'
      @dummy.sha1.should_not == temp

      @test_root.files.should have(1).things
    end

    it "downloads a file" do
      @dummy.download('dummy.down')
      `diff #{ @hello_file } dummy.down`.should == ""

      File.delete('dummy.down')
    end

    it "moves a file" do
      @test_temp = @test_root.create('temp')

      @dummy.move(@test_temp)
      @dummy.parent.should be @test_temp
    end

    it "copies a file" do
      @test_temp = @test_root.create('temp')
      clone = @dummy.copy(@test_temp)

      clone.parent.should be @test_temp
      clone.name.should == @dummy.name
      clone.should_not be @dummy
    end

    it "uploads a File object" do
      @test_temp = @test_root.create('temp')
      File.open(@vegetables) do |f|
        @test_temp.upload(f)
      end
      @test_temp.files.should have(1).things
    end

    it "uploads an UploadIO object" do
      @test_temp = @test_root.create('temp2')
      File.open(@vegetables) do |f|
        @test_temp.upload(UploadIO.new(f, 'text/plain', 'i_am_only_a_uploadio.txt'))
      end
      @test_temp.files.should have(1).things
    end

    it "renames a file" do
      @dummy.rename('bandito.txt')
      @dummy.name.should == 'bandito.txt'
    end

    it "deletes a folder" do
      @dummy.delete

      @dummy.parent.should be nil
      @test_root.files.should have(0).things
    end

    it "gets file comments" do
      @dummy.comments.should == []

      c1 = @dummy.add_comment("Hello World!")
      c2 = @dummy.add_comment("foo bar")

      temp = @dummy.comments(true).collect { |c| [ c.id, c.message ] }
      temp.should == [ [ c1.id, c1.message ], [ c2.id, c2.message ] ]
    end

    it "adds file comment" do
      c1 = @dummy.add_comment("Hello world")
      c1.id.should_not == nil
      c1.message.should == "Hello world"

      c2 = @dummy.comments.first
      c1.id.should == c2.id
      c1.message.should == c2.message
    end

    it "deletes file comment" do
      comment = @dummy.add_comment("Hello world")
      comment.delete.should == true

      @dummy.comments.should == []
    end

    it "gets/sets the file description" do
      @dummy.description.should == nil

      @dummy.set_description("Hello World")
      @dummy.description(true).should == "Hello World"

      @dummy.set_description("Hello New World")
      @dummy.description(true).should == "Hello New World"
    end
  end
end
