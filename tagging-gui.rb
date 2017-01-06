require 'shoes'
require './lib'

$MAX_DIR_DEPTH=5
$work_dir= ARGV[1] || Dir.home

Shoes.app(width:1024,height:768) {
  @current_image_index=-1
  @db = TagLibrary.new($work_dir)
  
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

    @db.load
    
    @output_area.append {
      para "Total images found #{@db.size}"
    }

    @current_image_index = 0
    edit_image
  }

  def edit_image
    if img = @db.fetch_item(@current_image_index) then
      setup_control_buttons unless @prev_button

      info "Show current_image #{img}"
      @current_image.clear
      @current_image.append{
        inscription img
        @transformed_image = inscription img
        _img=image img
        _img.width=400
      }
      
      setup_tag_buttons
    end
  end

  tag_checks=[]

  def setup_tag_buttons
    info "Create tag buttons!"
    @tag_checks||= []
    # get the previous selection's tag names
    prev_selected_tags=@tag_checks.select{ |tag, cb | cb.checked? }.map{ |t,c| t }
    # make a union with the tags already in the filename
    selected_tags= prev_selected_tags | @db.fetch_tags(@current_image_index)
    @tags.clear
    @tags.append{
      # creates a new [ [tag_name,cb] ... ] array
      @tag_checks= @db.tag_candidates(@current_image_index).map { |tag_name|
        @checkbox = check ; @p = para tag_name
        # mark checked via selected_tags
        @checkbox.checked = true if selected_tags.include? tag_name
        [tag_name, @checkbox]
      }
    }
  end

  def setup_control_buttons
    info "Setup control buttons!"
    @control_buttons.append do
      @prev_button = button "Prev"
      @next_button = button "Next"
      @del_button = button "Delete"
      @new_tag = edit_line(width:200)
      @new_tag_button = button 'Add New Tag'
      @del_tag_button = button 'Remove Checked tags'
      @check_button = button 'Check'
      @save_button=button "Save file"
    end
    @check_button.click do
      @transformed_image.replace @db.proposed_filename( @current_image_index, selected_tags )
    end
    @prev_button.click {
      @current_image_index -= 1
      edit_image
    }
    @next_button.click {
      @current_image_index += 1
      edit_image
    }
    @del_button.click {
      @db.delete_item(@current_image_index)
      edit_image
    }

    @new_tag_button.click do
      @db.add_tag_option @new_tag.text
      @new_tag.text=''
      setup_tag_buttons
    end

    @del_tag_button.click do
      @tag_checks.select{ |tag,check| check.checked? }.each do |tag, check|
        @db.remove_tag_option tag
      end
      setup_tag_buttons
    end

    @save_button.click do
      @db.store_tags(@current_image_index, selected_tags)
      @current_image_index += 1
      edit_image
    end
  end

  def selected_tags
    @tag_checks
      .select{ |tag, check| check.checked? }
      .map{|tag, check| tag}
  end

}

