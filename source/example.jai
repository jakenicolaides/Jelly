my_window: Window_Type;
window_width: s32 = 1920;
window_height: s32 = 1080;

MAIN_COLOUR: Vector4 : .{0.761, 0.86, 0.96, 1}; // light blue
ACCENT_COLOUR: Vector4 : .{0.243, 0.294, 0.576, 1}; // dark blue
SECONDARY_COLOUR: Vector4 : .{0.616, 0.749, 0.878, 1}; // slightly dark-er light blue
DEBUG_COLOUR: Vector4 : .{1, 0, 0, 1}; // Bright Red

main :: () {

    WANTED_MSAA :: 8;
    my_window = create_window(window_width, window_height, "JELLY EXAMPLE", wanted_msaa = WANTED_MSAA);
    msaa := Simp.prepare_window(my_window, wanted_msaa = WANTED_MSAA);
    window_width, window_height = Simp.get_render_dimensions(my_window);

    Simp.set_render_target(my_window, .LEFT_HANDED);
   
    jelly_ui: *Jelly.Element = Jelly.init(.{
        id = "MainBox",
        width = xx window_width,
        height = xx window_height,
        colour = MAIN_COLOUR,
        padding = .{25, 25, 25, 25},
        children = .[
            .{
                id = "ChildBox1",
                percent_width = 50,
                height = Jelly.GROW, 
                colour = DEBUG_COLOUR,
                padding = .{10,10,10,10},
                children = .[
                    .{
                        id = "ChildBox1Text",
                        percent_width = 50,
                        colour = SECONDARY_COLOUR, 
                        padding = .{50, 50, 50, 50},
                        border = .{1,1,1,1},
                        text_colour = ACCENT_COLOUR,
                        font_size = 24,
                        text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. \n\n It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
                    },
                    .{
                        id = "ChildBox1Text2",
                        percent_width = 50,
                        font_size = 24,
                        colour = MAIN_COLOUR,
                        text_colour = ACCENT_COLOUR,
                        padding = .{50, 50, 50, 50},
                        text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
                    }
                ]
            },
            .{
                id = "ChildBox3",
                width = Jelly.GROW,
                height = Jelly.GROW, 
                display = .BLOCK,
                colour = SECONDARY_COLOUR, 
                children = .[
                    .{
                        id = "Inspector",
                        percent_width = 100,
                        padding = .{25,25,25,25},
                        colour = SECONDARY_COLOUR,
                        text_colour = ACCENT_COLOUR,
                        border = .{1,1,1,1},
                        font_size = 24,
                        text = "Give me some text"
                    },
                    .{
                        id = "TestButtonA",
                        percent_width = 25,
                        height = 400,
                        colour = ACCENT_COLOUR,
                        on_click = (){ 
                            log("You clicked on button a!");
                        },
                        text = "Button A",
                        font_size = 24,
                        padding = .{25,25,25,25},
                    },
                    .{
                        id = "TestButtonB",
                        percent_width = 25,
                        height = 400,
                        colour = .{0.1,0.4, 0.3, 1},
                        on_click = (){ 
                            log("You clicked on button b!");
                        },
                        text = "Button B",
                        font_size = 24,
                        padding = .{25,25,25,25},
                    },
                    .{
                        id = "ChildBox_copy",
                        percent_width = 100,
                        height = 300, 
                        colour = SECONDARY_COLOUR, 
                        children = .[
                            .{
                                id = "TestButtonC",
                                percent_width = 25,
                                colour = ACCENT_COLOUR,
                                on_click = (){ 
                                    log("You clicked on button C copy!");
                                },
                                text = "Button C",
                                font_size = 24,
                                padding = .{25,25,25,25},
                            },
                            .{
                                id = "InputTypeA",
                                percent_width = 75,
                                height = 600,
                                colour = .{0.1,0.4, 0.3, 1},
                                text = "This input has a max characters of 50",
                                font_size = 24,
                                padding = .{25,25,25,25},
                                input_type = .TEXT,
                                max_characters = 50

                            }
                        ]
                    },  

                ]
            },
            .{
                id = "ChildBox4",
                width = 40,
                height = Jelly.GROW, 
                colour = MAIN_COLOUR,
                padding = .{10, 0,10,10},
                children = .[
                    .{
                        id = "GranchildBox",
                        width = Jelly.GROW,
                        percent_height = 30, 
                        colour = ACCENT_COLOUR, 
                    }
                ]
            }
        ]
    });

    quit := false;
    want_screenshot := false;
    while !quit {
        Jelly.tick(jelly_ui, my_window);
        for Input.events_this_frame {
            if (it.type == .KEYBOARD && it.key_code == .ESCAPE) quit = true;
        }
    }
}

#import "Basic";
#import "Window_Creation";
#import "Math";
Simp  :: #import "Simp";
Input :: #import "Input";
Jelly :: #import "Jelly";
