CURSOR_COLOUR: Vector4: .{1, 0, 0, 1}; // Bright Red

scissor_stack: [..] Rect;
is_scissor_active: bool = false;
focused_input: *Element;
input_scrub: int;

GROW: float: -2;
CONTENTS: float: -3;  

DISPLAY :: enum u32 {
    INLINE;
    BLOCK; 
}

INPUT_TYPE :: enum u32 {
    NONE;
    TEXT;
    NUMBER;
    SELECT;
    MULTI_SELECT;
}

Element :: struct{
    id: string;
    x: float;
    y: float;
    width: float = -1; 
    height: float = -1; 
    computed_width: float = -1;
    computed_height: float = -1;
    percent_width: float = -1;
    percent_height: float = -1;
    colour: Vector4;
    padding: Vector4;
    display: DISPLAY = .INLINE;
    text: string; 
    text_colour: Vector4 = .{1,1,1,1};
    font_size: int = 12;
    line_height: float = 1.5;
    children: [] Element;
    font: *Simp.Dynamic_Font;
    border: Vector4; //(x, y, z, w) → (left, top, right, bottom)
    border_colour: Vector4;
    scroll_offset: Vector2 = .{0, 0}; 
    is_overflowing: bool = false;
    input_type: INPUT_TYPE;
    max_characters: int = -1;
    on_click: ();
}


tick :: (jelly_ui: *Element, my_window: *NSWindow) {

   
    Input.update_window_events();
    x, y, success := get_mouse_pointer_position(my_window, true);
    y = cast(int)jelly_ui.computed_height - y;  // Flip Y axis to match rendering coordinates

    for Input.get_window_resizes() {
        Simp.update_window(it.window);  // Simp will do nothing if it doesn't care about this window.
        if it.window == my_window {
            jelly_ui.width = xx it.width;
            jelly_ui.height = xx it.height;
            reset_computed_dimensions(jelly_ui);
           // test_text = sprint("Window resized to (%,%)", jelly_ui.width, jelly_ui.height);
        }
    }
    for Input.events_this_frame {
        if it.type == {
            case .KEYBOARD;

                if(!it.key_pressed) break;

                // Mouse left click
                if it.key_code == .MOUSE_BUTTON_LEFT{
                    element_at_coord := get_element_at_coord(.{cast(float)x,cast(float)y}, jelly_ui);
                    if element_at_coord != null {   
                        if(element_at_coord.input_type != .NONE){
                            focused_input = element_at_coord;
                        }else{
                            focused_input = null;
                            input_scrub = 0;
                        }
                        if(element_at_coord.on_click != null){
                            element_at_coord.on_click();
                        }
                    }
                }

                // Scrubbing, enter and backspace
                if (focused_input != null){
                    if(it.key_code == .ARROW_LEFT && input_scrub < focused_input.text.count) input_scrub += 1;
                    if(it.key_code == .ARROW_RIGHT && input_scrub > 0) input_scrub -= 1;
                    
                    if(it.key_code == .BACKSPACE && focused_input.text.count > 0){
                        if(input_scrub >= focused_input.text.count){
                            // Do nothing
                        }else if(input_scrub > 0){
                            builder: String_Builder;
                            init_string_builder(*builder);
                            first_part := slice(focused_input.text, 0, focused_input.text.count - input_scrub - 1);
                            second_part := slice(focused_input.text, focused_input.text.count - input_scrub, focused_input.text.count);
                            append(*builder, first_part);
                            append(*builder, second_part);
                            focused_input.text = builder_to_string(*builder);
                        }else{
                            focused_input.text = slice(focused_input.text, 0, focused_input.text.count - 1);
                        }
                    }
                    if(it.key_code == .ENTER)focused_input = null;
                }

            case .TEXT_INPUT;
                
                if (focused_input != null){

                    if(focused_input.max_characters != -1 && focused_input.text.count >= focused_input.max_characters) break;

                    new_text_character: = cast(u8)it.utf32;
                    
                    builder: String_Builder;
                    init_string_builder(*builder);
                    if(input_scrub > 0){
                        first_part := slice(focused_input.text, 0, focused_input.text.count - input_scrub);
                        second_part := slice(focused_input.text, focused_input.text.count - input_scrub, focused_input.text.count);
                        append(*builder, first_part);
                        append(*builder, new_text_character);
                        append(*builder, second_part);
                    }else{
                        append(*builder, focused_input.text);
                        append(*builder, new_text_character);
                    }
                    
                    focused_input.text = builder_to_string(*builder);
                    
                }


            case .MOUSE_WHEEL;
                
                // Find the element you want to scroll
                scroll_target := get_element_at_coord(.{cast(float)x,cast(float)y}, jelly_ui);
               
                if(scroll_target != null && scroll_target.is_overflowing) {
                    if it.touch_type == .MOVED{ 
                        scroll_target.scroll_offset.y -= it.wheel_delta; // Arbitrary scroll speed
                        if(scroll_target.scroll_offset.y < 0) scroll_target.scroll_offset.y = 0;
                   
                        scroll_parent: *Element = get_element_parent(jelly_ui, scroll_target);
                        
                        scroll_parent_height: = scroll_parent.computed_height - scroll_parent.border.w - scroll_parent.padding.w - scroll_target.padding.w - scroll_target.border.w;
                       
                        scroll_limit: = scroll_target.computed_height - scroll_parent_height;

                        if(scroll_parent != null &&  scroll_target.scroll_offset.y > scroll_limit) scroll_target.scroll_offset.y = scroll_limit;
                        
                       // log("Scroll Target: %, : scroll_offset %", scroll_target.id, scroll_target.scroll_offset); 
                    }
                }
        }
    }

    layout(jelly_ui);
    position(jelly_ui);
    // Uncomment to see where the mouse pointer is
    //log("%", jelly_get_element_at_coord(.{cast(float)x,cast(float)y}, jelly_ui).id);
    
    container_render(jelly_ui);
    Simp.clear_scissor();
    text_render(jelly_ui);
    draw_cursor();
    Simp.swap_buffers(my_window);
    
    sleep_milliseconds(4);
    reset_temporary_storage();
}

// This function's main job is to take the struct literal passed in 
// and turn it into a dynamically allocated variable
init :: (element: Element) -> *Element {

    // Allocate a new Element on the heap
    allocated_element: *Element = alloc(size_of(Element));

    // Copy primitive fields
    allocated_element.* = element;

    // Recursively allocate children, if any
    child_count := element.children.count;
    if (child_count > 0) {
        allocated_children : []Element;
        allocated_children.data = alloc(size_of(Element) * child_count);
        allocated_children.count = child_count;

        // For each child, recursively initialize and copy into new array
        for 0..child_count - 1 {
            child_ptr := init(element.children[it]);
            allocated_children[it] = child_ptr;
        }

        allocated_element.children = allocated_children;
    }

    //Initialise the font for any elements with text
    if(allocated_element.text.count > 0){
        allocated_element.font = Simp.get_font_at_size(".", "Chicago.ttf", allocated_element.font_size);
    }

    // Allocate the text field
    allocated_element.text = sprint("%", allocated_element.text);
        
    return allocated_element;
}

/* --------------
Layout Functions 
----------------*/

debug_ui :: (e: *Element, indent: int = 0) {

    // string_builder : StringBuilder;
    builder: String_Builder;
    init_string_builder(*builder);
    if(indent > 0){
        for 0..indent - 1{
            append(*builder, "  ");
        }
    }
    indent_string := builder_to_string(*builder);
    
    log("% %: computed_width=%, computed_height=%, coordinate=(%,%)", indent_string, e.id, e.computed_width, e.computed_height, e.x, e.y);
    for *e.children {
       debug_ui(it, indent + 1);
    }
}

fixed_dimensions :: (element: *Element) {

    // If the width is fixed then copy that into computed
    if(element.width >= 0 && element.computed_width < 0){
        element.computed_width = element.width;
    }

    if(element.height >= 0 && element.computed_height < 0){
        element.computed_height = element.height;
    }

    for * element.children fixed_dimensions(it);
}

percent_dimensions :: (element: *Element, parent_element: *Element = null) {

    if(parent_element != null){

       if (element.width < 0 && element.percent_width > -1 && parent_element.computed_width >= 0) {

            content_width : float = parent_element.computed_width 
                                  - (parent_element.border.x + parent_element.border.z)
                                  - (parent_element.padding.x + parent_element.padding.z);

            element.computed_width = (content_width / 100) * element.percent_width;
        }

         if (element.height < 0 && element.percent_height > -1 && parent_element.computed_height >= 0) {
            content_height : float = parent_element.computed_height 
                                  - (parent_element.border.y + parent_element.border.w)
                                  - (parent_element.padding.y + parent_element.padding.w);

            element.computed_height = (content_height / 100) * element.percent_height;
        }
    }

    for *element.children percent_dimensions(it, element);
}

calculate_contents_width :: (elements: []Element) -> float {
    width: float = 0;
    for *elements width += it.computed_width;
    return width;
}

calculate_contents_height :: (elements: []Element) -> float {
    min_height: float = 0;
    for *elements {
        if(min_height < it.computed_height) min_height = it.computed_height;
    }
    return min_height;
}


grow_dimensions :: (element: *Element, parent_element: *Element = null){

    // If width grower, then accumulate children widths
    if(element.width == GROW){
        sibling_widths: float = 0;
        for parent_element.children{
            if (it.id == element.id) continue;
            sibling_widths += it.computed_width;
        }
        if(parent_element.computed_width >= 0) element.computed_width = parent_element.computed_width - sibling_widths - parent_element.padding.x - parent_element.padding.z - element.border.x - element.border.z;
    }

    // If height grower, then accumulate children height
    if(element.height == GROW){
        if(parent_element.computed_height >= 0) element.computed_height = parent_element.computed_height - parent_element.padding.y - parent_element.padding.w - parent_element.border.y - parent_element.border.w;
    }

    for * element.children{
        grow_dimensions(it, element);
    }
    
}

contents_dimensions :: (element: *Element){

    if(element.width == CONTENTS){
        element.computed_width = calculate_contents_width(element.children);
        // If the element is CONTENTS then its padding is added like margin
        element.computed_width += element.padding.x + element.padding.z - element.border.x - element.border.z; 
    }
    if(element.height == CONTENTS){
        element.computed_height = calculate_contents_height(element.children);
        // If the element is CONTENTS then its padding is added like margin
        element.computed_height += element.padding.y + element.padding.w - element.border.y - element.border.w;
    }

    for * element.children{
        contents_dimensions(it);
    }
}



text_dimensions :: (element: *Element, parent_element: *Element = null){

    if(element.text.count > 0 ){
        // 1) compute the inner width
        content_width := element.computed_width - (element.padding.x + element.padding.z);

        raw_text: string = element.text;
        raw_blocks := split_preserve_empty_lines(raw_text, "\n");
        line_count: int = 0;

        for raw_block: raw_blocks {

            raw_block_no_whitespace := replace(raw_block, " ", "");

            if raw_block_no_whitespace.count == 0 { 
                line_count += 1;
                continue;
            }


            words := split(raw_block, " ");
            current_line := "";

            for word: words {
                test_line := ifx(current_line.count > 0) then tprint("% %", current_line, word) else word;
                test_width := xx Simp.prepare_text(element.font, test_line);

                if xx test_width > content_width {
                    line_count += 1;
                    current_line = word;
                } else {
                    current_line = test_line;
                }
            }

            if current_line.count > 0 {
                line_count += 1;
            }
        }

        // 3) include top & bottom padding in final height
        text_block_height := cast(float)line_count * (element.line_height * element.font.character_height);
        element.computed_height = text_block_height + element.padding.y + element.padding.w - parent_element.padding.y - parent_element.padding.w;
    }

    for * element.children text_dimensions(it, element);
}

check_resolved :: (element: *Element) -> bool{
    if(element.computed_height < 0 || element.computed_width < 0){
        return false;
    }else{
        for *element.children {
            if (!check_resolved(it)) {
                return false;
            }
        }
        return true;
    }
}

reset_computed_dimensions :: (element: *Element){

    element.computed_width = -1;
    element.computed_height = -1;
    element.scroll_offset = .{0,0};

    for * element.children reset_computed_dimensions(it);

}

layout :: (root: *Element){

    fixed_dimensions(root);
    percent_dimensions(root);
    contents_dimensions(root);
    grow_dimensions(root);
    text_dimensions(root);

    if(!check_resolved(root)){
        layout(root);
    }
    

}

/* --------------
Position Functions 
----------------*/

zero_position :: (element: *Element){
    element.x = 0;
    element.y = 0;
    for * element.children zero_position(it);
}

child_position :: (element: *Element, parent_element: *Element = null){
    if(element.children.count > 0){
        accumulated_width : float = 0;
        accumulated_height : float = 0;

        if(element.display == .INLINE){
            for 0..element.children.count - 1{
                child : *Element= *element.children[it];
                
                // First child doesn't get pushed by anything but takes up space
                if(it == 0){
                    child.x = accumulated_width;
                    accumulated_width = child.computed_width;
                    continue;
                }
                child.x = accumulated_width;
                accumulated_width += child.computed_width;
            } 
        }else if(element.display == .BLOCK){
            for 0..element.children.count - 1{

                child : *Element= *element.children[it];
                
                // First child doesn't get pushed by anything but takes up space
                if(it == 0){
                    child.y = accumulated_width;
                    accumulated_height = child.computed_height;
                    continue;
                }
                child.y = accumulated_height;
                accumulated_height += child.computed_height;
            } 
        }
        for * element.children child_position(it, element);
        
    }
}

inherit_position :: (element : *Element){
    for * element.children {

        it.x += element.x + element.border.x + element.padding.x; 
        it.y += element.y + element.border.y + element.padding.y - element.scroll_offset.y; 

        inherit_position(it);  // Recursive call on the child
    }
}

position :: (element: *Element){
    zero_position(element);
    child_position(element);
    inherit_position(element);
}

calculate_scroll_max_y :: (element: *Element) -> float {
    content_bottom := 0.0;
    for *element.children {
        bottom := it.y + it.computed_height;
        if bottom > content_bottom {
            content_bottom = bottom;
        }
    }
    // The difference between content height and visible height
    return max(content_bottom - element.computed_height, 0);
}

/* --------------
Render Functions 
----------------*/

container_render :: (element: *Element, parent: *Element = null){

    // Clipping
    // @Todo: We should only clip if necessary
    clip_min : Vector2 = .{
        x = element.x,
        y = element.y
    };
    clip_max : Vector2 = .{
        x = element.x + element.computed_width,
        y = element.y + element.computed_height
    };

    clip_width := clip_max.x - clip_min.x;
    clip_height := clip_max.y - clip_min.y;

    element.is_overflowing = (parent != null && clip_height > parent.computed_height);

    element_height: = element.computed_height;
    if(element.is_overflowing && parent != null){
        element_height = parent.computed_height - parent.padding.y - parent.padding.w;
    }else{
        element.scroll_offset = .{0,0};
    }
    
    // draw border & background
    if element.border.x > 0 || element.border.y > 0 || element.border.z > 0 || element.border.w > 0 {
        Simp.immediate_quad(
            element.x, 
            element.y,
            element.x + element.computed_width, 
            element.y + element_height,
            element.border_colour
        );
        Simp.immediate_quad(
            element.x + element.border.x,
            element.y + element.border.y,
            element.x + element.computed_width - element.border.z,
            element.y + element_height - element.border.w,
            element.colour
        );
    } else {
        Simp.immediate_quad(
            element.x, 
            element.y,
            element.x + element.computed_width, 
            element.y + element_height,
            element.colour
        );
    }

    // This is what is responsible for drawing the border basically
    push_scissor(.{clip_min.x, clip_min.y + element.border.y + element.padding.y, clip_width, element_height - element.border.w - element.padding.w});
    
    
    // Render children (they’ll be clipped to the scissor rect)
    if element.children.count > 0 {
        for * element.children container_render(it, element);
        //for * element.children jelly_text_render(it);
    }   

    // @Todo: we should only pop if we've pushed 
    pop_scissor(); 
}



text_render :: (element: *Element, parent: *Element = null){
    if(element.text.count > 0){

        /* Clipping */
        clip_min : Vector2 = .{
            x = element.x + element.padding.x,
            y = element.y + element.padding.y
        };
        clip_max : Vector2 = .{
            x = element.x + element.computed_width + element.padding.z,
            y = element.y + element.computed_height + element.padding.w
        };

        // An overflowing text element's computed height can't be used to calculate the clip
        // rectangle becuase its bigger than its parent, so we use the parent's height
        if(element.is_overflowing && parent != null){
            parent_container_height: = parent.computed_height + parent.border.w + parent.padding.w;
            clip_max.y = parent_container_height - element.border.w - element.padding.w;
        }
        clip_width := clip_max.x - clip_min.x;
        clip_height := clip_max.y - clip_min.y;

        push_scissor(.{clip_min.x, clip_min.y , clip_width, clip_height});    

        
        line_y_offset := 0;

        raw_text: string = element.text;
        raw_blocks := split_preserve_empty_lines(raw_text, "\n");
        line_y_offset = 0;

        content_width: = element.computed_width - (element.padding.x + element.padding.z);

        for raw_block: raw_blocks {

            raw_block_no_whitespace := replace(raw_block, " ", "");

            if raw_block_no_whitespace.count == 0 {       
                line_y_offset += 1;
                continue;
            }

            words := split(raw_block, " ");
            current_line := "";

            for word: words {
                test_line := ifx(current_line.count > 0) then tprint("% %", current_line, word) else word;
                test_width := Simp.prepare_text(element.font, test_line);

                if xx test_width > content_width {
                    Simp.prepare_text(element.font, current_line);
                    Simp.draw_prepared_text(
                        element.font,
                        xx (element.x + element.padding.x),
                        xx (element.y + element.padding.y - element.scroll_offset.y + element.font.character_height + (line_y_offset * (element.line_height * element.font.character_height))),
                        element.text_colour
                    );
                    current_line = word;
                    line_y_offset += 1;
                } else {
                    current_line = test_line;
                }
            }

            if current_line.count > 0 {
                Simp.prepare_text(element.font, current_line);
                Simp.draw_prepared_text(
                    element.font,
                    xx (element.x + element.padding.x),
                    xx (element.y + element.padding.y - element.scroll_offset.y + element.font.character_height + (line_y_offset * (element.line_height * element.font.character_height))),
                    element.text_colour
                );
                line_y_offset += 1;
            }
        }

       
        
    }
    

    if(element.children.count > 0) for * element.children text_render(it, element);

    // @Todo: we should only pop if we've pushed 
    // @todo we should only clip if necessary no?
    if(element.text.count > 0 ) pop_scissor(); 
}

/*---------
   Input
---------*/

get_element_at_coord :: (coords: Vector2, element: *Element) -> *Element {
    x_max := element.x + element.computed_width;
    y_max := element.y + element.computed_height;

    element_in_bounds := false;
    if (coords.x > element.x && coords.x < x_max &&
        coords.y > element.y && coords.y < y_max) {
        element_in_bounds = true;
    }

    if element_in_bounds {
        best_match: *Element = null;

        // Check children first
        for *element.children {
            match := get_element_at_coord(coords, it);
            if (match != null) {
                best_match = match;
            }
        }

        // If no children matched, this parent is the deepest match
        if (best_match == null) {
            return element;
        } else {
            return best_match;
        }
    }

    return null;
}

draw_cursor :: (){

    // Note: this only works for single line text input because that's all we have so far

    if(focused_input != null){



        text_sample := slice(focused_input.text, 0, focused_input.text.count - input_scrub);
        text_width := Simp.prepare_text(focused_input.font,  text_sample);

        x_pos:= focused_input.x + focused_input.padding.x + text_width;
        y_pos:= focused_input.y + focused_input.padding.y;
       // log("drawing cursor at {%, %}", focused_input.x,focused_input.y);
        Simp.immediate_quad(
            x_pos, 
            y_pos - 3,
            x_pos + 3, 
            y_pos + focused_input.font.character_height * 1.5,
            CURSOR_COLOUR
        );
    }
}


/* -----------------
   Misc Jelly Stuff
-------------------*/

find_element_by_id :: (id: string, element: *Element) -> *Element {
    

    if (element.id == id) return element;

    for * child: element.children {
        result := find_element_by_id(id, child);
        if (result != null) {
            return result;
        }
    }

    return null;
}

get_element_parent :: (root_element: *Element, child_element: *Element) -> *Element{

    if (root_element.children.count > 0) {
        for * root_element.children {
            if (child_element.id == it.id) {
                return root_element;
            } else if (it.children.count > 0) {
                parent_found := get_element_parent(it, child_element);
                if (parent_found != null) {
                    return parent_found;
                }
            }
        }
        return null;
    }

    return null;
}

//
//  split_keep_empties :: Like split(), except it does NOT discard
//  zero-length substrings that occur between consecutive separators.
//  (Works for either u8 or string separators, same generic style as split().)
//
split_preserve_empty_lines :: (s: string, separator: $T) -> []string {   // 'separator' must be u8 or string.
    #assert (T == u8) || (T == string);

    result: [..]string;                     // dynamic array of string slices
    remainder := s;

    while true {
        // always attempt a split, even when remainder could be ""
        found, left, right := split_from_left(remainder, separator);

        array_add(*result, left);           // <-- even empty 'left' is preserved

        if !found {
            break;                          // no more separators – we're done
        }

        remainder = right;                  // keep scanning the tail
    }

    return result;
}

/* --------------
  GetRect stuff 
---------------*/

Rect :: struct {
    x, y: float;
    w, h: float;
}

push_scissor :: (_rect: Rect) {

    Simp.set_shader_for_color();
    rect := _rect;

    if scissor_stack {
        top := peek_pointer(scissor_stack);
        rect = intersect(top.*, rect);
    }

    set_scissor(rect);
    array_add(*scissor_stack, rect);
}

intersect :: (a: Rect, b: Rect) -> Rect {
    x := max(a.x, b.x);
    y := max(a.y, b.y);

    w := max(min(a.x+a.w, b.x+b.w) - x, 0);
    h := max(min(a.y+a.h, b.y+b.h) - y, 0);

    rect := get_rect(x, y, w, h);
    return rect;
}

get_rect :: (x: float, y: float, w: float, h: float) -> Rect {
    r: Rect;
    r.x = x;
    r.y = y;
    r.w = w;
    r.h = h;
    return r;
}

pop_scissor :: () {
    pop(*scissor_stack);

    if scissor_stack {
        r := peek(scissor_stack);
        set_scissor(r);
    } else {
        Simp.clear_scissor();
    }
}

set_scissor :: (r: Rect) {

    x0 := cast(s32) r.x;
    y0 := cast(s32) r.y;
    x1 := cast(s32) (r.x + r.w );
    y1 := cast(s32) (r.y + r.h );

    Simp.set_scissor(x0, y0, x1, y1);
}

Simp  :: #import "Simp";
Input :: #import "Input";
#import "Objective_C";
#import "Objective_C/AppKit";
#import "Window_Creation";
#import "Basic";
#import "Math";
#import "System";  // For get_path_of_running_executable. @Cleanup.
#import "String";  // For path_strip_filename. @Cleanup.