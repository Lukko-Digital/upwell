shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE:hint_screen_texture;
uniform float intensity : hint_range(0,1) = 1.0;

vec4 screen( vec4 base, vec4 blend )
{
  return 1.0 - (1.0 - base) * (1.0 - blend);
}

void fragment()
{
  vec4 bg_color = texture( SCREEN_TEXTURE, SCREEN_UV );

  // mix() if you want to be able to set 'intensity' to different values.
  COLOR.rgb = mix( COLOR, screen(bg_color,COLOR), intensity ).rgb;

  // No need to mix() if you always want 'intensity' to be 1.0 (uncomment):
  // COLOR.rgb = screen( bg_color, COLOR ).rgb;
}