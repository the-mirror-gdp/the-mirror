
const int _print_number_max_float_digits = 5;
const int _print_number_scale = 2;
const int _print_number_stretch_x = 1;
const int _print_number_stretch_y = 1;

float num_bit(int num, int x, int y)
{
    if (x < 0 || y < 0 || x >= 3 || y >= 5)
        return 0.0;

    int bit = (1) << (x + 3*y);

    // godot users: change int[](...) to {...}
    //int array[] = int[](0x01C0, 0x2000, 0x7B6F, 0x749A, 0x73E7, 0x79E7, 0x49ED, 0x79CF, 0x7BCF, 0x4927, 0x7BEF, 0x79EF);
    // or: (has an offset '1' and '.' glyphs, so it's "stretchable")
    int array[] = {0x01C0, 0x4000, 0x7B6F, 0x4924, 0x73E7, 0x79E7, 0x49ED, 0x79CF, 0x7BCF, 0x4927, 0x7BEF, 0x79EF};

    int mask = 0;
    if (num >= -2 && num <= 9)
        mask = array[num+2];

    if ((mask & bit) > 0)
        return 1.0;
    return 0.0;
}

ivec2 char_size()
{
    return ivec2(4 + _print_number_stretch_x, 6 + _print_number_stretch_y*2) * _print_number_scale;
}

int number_width(float num)
{
    int int_digits = 1;
    int num2 = int(num);
    while(num2 >= 10)
    {
        int_digits += 1;
        num2 /= 10;
    }

    return (int_digits + _print_number_max_float_digits + 1)*(4 + _print_number_stretch_x);
}
vec4 get_number(ivec2 px, float num)
{
    if (px.y < 0 || px.x < 0)
        return vec4(0.0);

    px /= _print_number_scale;

    int y_mid = 2+_print_number_stretch_y;
    int y_end = 4+_print_number_stretch_y*2;

    if (px.y == 0)
        px.y = 0;
    else if (px.y > 0 && px.y < y_mid)
        px.y = 1;
    else if (px.y == y_mid)
        px.y = 2;
    else if (px.y > y_mid && px.y < y_end)
        px.y = 3;
    else if (px.y == y_end)
        px.y = 4;
    else
        return vec4(0.0);

    int x_end = 2+_print_number_stretch_x;

    int _x = px.x % (4 + _print_number_stretch_x);
    int which_digit = px.x / (4 + _print_number_stretch_x);

    if (_x == 0)
        px.x = 0;
    else if (_x > 0 && _x < x_end)
        px.x = 1;
    else if (_x == x_end)
        px.x = 2;
    else
        return vec4(0.0);

    int int_digits = 1;
    int num2 = abs(int(num));
    while(num2 >= 10)
    {
        int_digits += 1;
        num2 /= 10;
    }

    if (which_digit - int_digits > _print_number_max_float_digits)
        return vec4(0.0);

    int digit = -1;

    if (num < 0.0)
    {
        if (which_digit == 0)
            digit = -2;
        which_digit -= 1;
    }

    if (which_digit >= 0 && which_digit < int_digits)
    {
        which_digit = int_digits - which_digit - 1;
        digit = abs(int(num));
        for(int i = 0; i < which_digit; i += 1)
            digit /= 10;
        digit = (digit % 10 + 10) % 10;
    }
    else if (which_digit > int_digits)
    {
        which_digit = which_digit - int_digits;
        float factor = 1.0;
        for(int i = 0; i < which_digit; i += 1)
            factor *= 10.0;

        int num3 = int(mod(abs(fract(num)) * factor, 10.0));

        digit = int(num3) % 10;
    }

    ivec2 digit_px = ivec2(((px.x % 4) + 4) % 4, (((px.y % 6) + 6) % 6));

    return vec4(num_bit(digit, digit_px.x, digit_px.y));
}

vec4 print_number(ivec2 px, float num, vec4 in_color, vec4 text_color)
{
    vec4 out_color = get_number(px, num) * text_color;
    return mix(in_color, out_color, out_color.a);
}
