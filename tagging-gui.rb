require 'shoes'

$MAX_DIR_DEPTH=3
$original_dir= Dir.pwd
$work_dir= ARGV[1] || Dir.chdir

Shoes.app(width:1024,height:768) {
  @current_image_index=-1
  
  stack( margin: 4 ) {
    flow {
      title "Photo tagging"
      # para "ARGV: #{ARGV.join(', ')}"
      @label= para "In directory : #{$work_dir}"
      @scan_button = button("Scan directory")
    }
  
    flow(margin: 4){
      @control_buttons=flow(margin: 10)
      @tags=flow(margin:2)
    }
    
    @current_image=stack
    @output_area=stack(margin:0,width:768)
    #@images_area = flow( margin: 2)
  }
  
  @scan_button.click {
    @output_area.append {
      inscription "Looking up #{$work_dir} for images..."
    }

    start_thread
  }

  def edit_image
    if img = @source_images[@current_image_index] then
      setup_control_buttons unless @prev_button

      info "Show current_image #{img}"
      @current_image.clear
      @current_image.append{
        inscription img
        _img=image img
        _img.width=400
      }
      
      setup_tag_buttons
    end
  end

  DEFAULT_TAGS=[ 'mtb', 'mountains', 'travel', 'people', 'profile' ]
  tag_checks=[]

  def setup_tag_buttons
    info "Create tag buttons!"
    @tag_checks||= []
    # get the previous selection's tag names
    prev_selected_tags=@tag_checks.select{ |tag, cb | cb.checked? }.map{ |t,c| t }
    # make a union with the tags already in the filename
    selected_tags= prev_selected_tags | fname_tags
    @tags.clear
    @tags.append{
      # creates a new [ [tag_name,cb] ... ] array
      @tag_checks= tag_candidates.map { |tag_name|
        @checkbox = check ; @p = para tag_name
        # mark checked via selected_tags
        @checkbox.checked = true if selected_tags.include? tag_name
        [tag_name, @checkbox]
      }
    }
  end

  def fname_tags
    File.basename(@source_images[@current_image_index]).split(/[_.]/)
  end

  # TODO ordering : keep date upfront!
  def tag_candidates
    ( fname_tags | DEFAULT_TAGS ).sort
  end

  def setup_control_buttons
    info "Setup control buttons!"
    @control_buttons.append do
      @prev_button = button "Prev"
      @next_button = button "Next"
      @new_tag = edit_line(width:200)
      @new_tag_button = button 'Add New Tag'
      @del_tag_button = button 'Remove Checked tags'
      @save_button=button "Save file"
    end
    @prev_button.click {
      @current_image_index -= 1
      edit_image
    }
    @next_button.click {
      @current_image_index += 1
      edit_image
    }

    @new_tag_button.click do
      DEFAULT_TAGS.push(@new_tag.text)
      @new_tag.text=''
      setup_tag_buttons
    end

    @del_tag_button.click do
      @tag_checks.select{ |tag,check| check.checked? }.each do |tag, check|
        DEFAULT_TAGS.delete(tag)
      end
      setup_tag_buttons
    end

    @save_button.click do
      rename_file_to_store_tags_in_filename
    end
  end

  def rename_file_to_store_tags_in_filename
    info 'rename file to store tags in filename! not implented yet'
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
}
