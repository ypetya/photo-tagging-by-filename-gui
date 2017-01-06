#TODO : display orig dimensions
class TagLibrary
  def initialize(source_dir)
    @source_images=[]
    @tags=['sport', 'min', 'people', 'personal-id']
    @source_dir = source_dir
  end

  # find files and store them
  def load
    start_thread.join
  end

  def fetch_item(index)
    @source_images[index]
  end

  def delete_item(index)
    file_name=fetch_item(index)
    File.delete file_name
    @source_images.delete(file_name)
  end

  def fetch_tags(index)
    file_name = @source_images[index]
    time_stamp = fetch_file_creation_time(file_name)
    file_name_tags = File.basename(@source_images[index]).split(/[_.]/)
    file_name_tags.reject! { |tag| tag=~ /jpg|jpeg|png|gif/i }
    ([ time_stamp ] | file_name_tags).uniq
  end

  def proposed_filename(index, tags)
    file_name = @source_images[index]
    new_file_name = tags.join('_')
    "#{File.dirname(file_name)}/#{new_file_name}#{File.extname(file_name)}"
  end

  def store_tags(index, tags)
    file_name = @source_images[index]
    new_name = proposed_filename(index, tags)
    File.rename( file_name, new_name )
    @source_images[index]=new_name
  rescue Exception => e
    error e
  end

  def add_tag_option(text)
    @tags.push text
  end

  def remove_tag_option(text)
    @tags.delete text
  end

  def tag_candidates(index)
    ( fetch_tags(index) | @tags ).sort
  end

  def size
    @source_images.length
  end

  def fetch_file_creation_time file_name
    fs = File::Stat.new(file_name)
    fs.ctime.strftime('%Y%m%d')
  end
    

  def start_thread
    Thread.new {
      info "New thread is firing up" 
      @source_images=[]

      original_dir = Dir.pwd
      Dir.chdir($work_dir)

      lookup_recursively($MAX_DIR_DEPTH) { |dir, file|
        img = "#{dir}/#{file}"
        info "Image found #{img}"
        @source_images.push(img)
      }
    
      Dir.chdir(original_dir)
      
      info "Thread finished."
    }
  end

  def lookup_recursively(maxdepth, &block)
    return if maxdepth == 0
    # check all the file extensions
    ['jpg','jpeg','png','gif'].each do |ext|
      Dir.glob("*.#{ext}") do |file|
        yield(Dir.pwd, file)
      end
    end
    # get all the dirs
    dirs=Dir.glob('*').select { |f| File.directory? f }

    dirs.each do |dir|
      # Do not process symlink
      next if File.symlink? dir
      # Do not process cache dirs
      next if dir =~ /viber|library|^\.git|AppData/i
      
      Dir.chdir(dir)
      lookup_recursively(maxdepth-1, &block)
      Dir.chdir('..')
    end
  rescue Exception => e
    error e
  end
end

