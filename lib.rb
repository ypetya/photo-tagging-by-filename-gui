
class TagLibrary
  def initialize(source_dir, orig_dir)
    @source_images=[]
    @source_dir = source_dir
    @orig_dir = orig_dir
  end

  # find files and store them
  def load
    start_thread
  end

  def fetch_item(index)
  end

  def fetch_tags(index)
    File.basename(@source_images[index]).split(/[_.]/)
  end

  def store_tags(index, tags)
  end

  def start_thread
    Thread.new {
      info "New thread is firing up" 
      @source_images=[]

      Dir.chdir($work_dir)

      lookup_recursively($MAX_DIR_DEPTH) { |dir, file|
        img = "#{dir}/#{file}"
        info "Image found #{img}"
        @source_images.push(img)
      }
    
      Dir.chdir($original_dir)
      
      info "Thread finished."

      @output_area.append {
        para "Total images found #{@source_images.length}"
      }

      @current_image_index = 0
      edit_image
    }
  end

  def lookup_recursively(maxdepth, &block)
    return if maxdepth == 0
    
    Dir.glob('*.jpg') do |file|
      yield(Dir.pwd, file)
    end
    
    dirs=Dir.glob('*').select { |f| File.directory? f }

    dirs.each do |dir|
      # Do not process symlink
      next if File.symlink? dir
      Dir.chdir(dir)
      lookup_recursively(maxdepth-1, &block)
      Dir.chdir('..')
    end
  end
end
