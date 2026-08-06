//
//  render.m
//  img2nes - kontrolværktøj
//
//  Gengiver et sæt .nmt + .chr + .pal som PPU'en ville vise det, og skriver resultatet
//  som PNG. Det er den eneste måde at se om attributterne rent faktisk lander rigtigt -
//  tallene i konverteringen kan sagtens se pæne ud mens billedet er forskudt.
//
//  Baggrundens mønstertabel ligger på $1000, altså CHR-offset 4096, jf. PPU_CTRL i img.h.
//  Attributformlen er hardwarens egen: én byte per 32x32 pixels, fire kvadranter à to bit.
//
//  Oversæt og kør:
//      clang -fobjc-arc -framework Cocoa render.m -o render
//      ./render mitbillede            # læser mitbillede.nmt/.chr/.pal
//                                     # skriver mitbillede_nes.png
//

#import <Cocoa/Cocoa.h>

static const uint8_t nes[64][3] = {
 {102,102,102},{0,42,136},{20,18,167},{59,0,164},{92,0,126},{110,0,64},{108,6,0},{86,29,0},
 {51,53,0},{11,72,0},{0,82,0},{0,79,8},{0,64,77},{0,0,0},{0,0,0},{0,0,0},
 {173,173,173},{21,95,217},{66,64,255},{117,39,254},{160,26,204},{183,30,123},{181,49,32},{153,78,0},
 {107,109,0},{56,135,0},{12,147,0},{0,143,50},{0,124,141},{0,0,0},{0,0,0},{0,0,0},
 {255,254,255},{100,176,255},{146,144,255},{198,118,255},{243,106,255},{254,110,204},{254,129,112},{234,158,34},
 {188,190,0},{136,216,0},{92,228,48},{69,224,130},{72,205,222},{79,79,79},{0,0,0},{0,0,0},
 {255,254,255},{192,223,255},{211,210,255},{232,200,255},{251,193,255},{254,194,231},{254,204,193},{247,216,165},
 {225,229,145},{205,238,145},{190,242,166},{182,240,199},{184,231,241},{186,186,186},{0,0,0},{0,0,0}};

#define BACKGROUND_TABLE 4096   // $1000

int main(int argc, const char **argv)
{
    @autoreleasepool
    {
        if(argc < 2)
        {
            fprintf(stderr, "render - draw a set of NES background files as a PNG\n\n");
            fprintf(stderr, "Usage: render <name>\n\n");
            fprintf(stderr, "  Reads <name>.nmt, <name>.chr and <name>.pal and writes <name>_nes.png.\n");
            fprintf(stderr, "  The nametable may be 960 bytes, or 1024 with the attributes appended;\n");
            fprintf(stderr, "  without them every tile is drawn with palette 0.\n");
            return 1;
        }

        NSString *base = @(argv[1]);

        // Et navn med endelse er en nem fejl at lave - så ville vi lede efter "x.nmt.nmt"
        if([@[@"nmt", @"chr", @"pal"] containsObject:base.pathExtension.lowercaseString])
            base = [base stringByDeletingPathExtension];

        NSData *nmt = [NSData dataWithContentsOfFile:[base stringByAppendingPathExtension:@"nmt"]];
        NSData *chr = [NSData dataWithContentsOfFile:[base stringByAppendingPathExtension:@"chr"]];
        NSData *pal = [NSData dataWithContentsOfFile:[base stringByAppendingPathExtension:@"pal"]];

        // Sig hvilken fil der mangler. "mangler filer" hjælper ikke når man har travlt.
        if(!nmt || !chr || !pal)
        {
            if(!nmt) fprintf(stderr, "Error: could not read '%s.nmt'\n", base.UTF8String);
            if(!chr) fprintf(stderr, "Error: could not read '%s.chr'\n", base.UTF8String);
            if(!pal) fprintf(stderr, "Error: could not read '%s.pal'\n", base.UTF8String);
            return 1;
        }

        // Uden de her læses der uden for filerne på et afkortet sæt
        if(nmt.length < 960)
        {
            fprintf(stderr, "Error: a nametable is 960 bytes (1024 with attributes); '%s.nmt' is %lu.\n",
                    base.UTF8String, (unsigned long)nmt.length);
            return 1;
        }

        if(chr.length < BACKGROUND_TABLE + 256*16)
        {
            fprintf(stderr, "Error: '%s.chr' is %lu bytes; the background table needs %d.\n",
                    base.UTF8String, (unsigned long)chr.length, BACKGROUND_TABLE + 256*16);
            return 1;
        }

        if(pal.length < 16)
        {
            fprintf(stderr, "Error: a palette is 16 bytes; '%s.pal' is %lu.\n",
                    base.UTF8String, (unsigned long)pal.length);
            return 1;
        }

        const uint8_t *n = nmt.bytes, *c = chr.bytes, *p = pal.bytes;
        const uint8_t *attr = (nmt.length >= 1024) ? n + 960 : NULL;

        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                       pixelsWide:256
                                                                       pixelsHigh:240
                                                                    bitsPerSample:8
                                                                  samplesPerPixel:3
                                                                         hasAlpha:NO
                                                                         isPlanar:NO
                                                                   colorSpaceName:NSCalibratedRGBColorSpace
                                                                      bytesPerRow:256*3
                                                                     bitsPerPixel:24];
        if(!rep)
        {
            fprintf(stderr, "Error: could not allocate the image.\n");
            return 1;
        }

        uint8_t *px = rep.bitmapData;

        for(int ny = 0; ny < 30; ny++)
            for(int nx = 0; nx < 32; nx++)
            {
                int tile = n[ny*32 + nx];
                int paletteIndex = 0;

                if(attr)
                {
                    // Én byte dækker 32x32 pixels; de fire kvadranter ligger som to bit hver,
                    // i rækkefølgen øverst-venstre, øverst-højre, nederst-venstre, nederst-højre.
                    int quadrant = ((ny % 4) / 2) * 2 + ((nx % 4) / 2);
                    paletteIndex = (attr[(ny/4)*8 + (nx/4)] >> (quadrant*2)) & 3;
                }

                for(int y = 0; y < 8; y++)
                {
                    int offset = BACKGROUND_TABLE + tile*16 + y;
                    uint8_t low = c[offset], high = c[offset + 8];

                    for(int x = 0; x < 8; x++)
                    {
                        int bit = 7 - x;
                        int value = ((low >> bit) & 1) | (((high >> bit) & 1) << 1);

                        // Indeks 0 er den fælles baggrundsfarve, uanset hvilken palette feltet har
                        int entry = (value == 0) ? p[0] : p[paletteIndex*4 + value];
                        const uint8_t *rgb = nes[entry & 0x3F];

                        int X = nx*8 + x, Y = ny*8 + y;
                        px[(Y*256 + X)*3 + 0] = rgb[0];
                        px[(Y*256 + X)*3 + 1] = rgb[1];
                        px[(Y*256 + X)*3 + 2] = rgb[2];
                    }
                }
            }

        NSString *out = [base stringByAppendingString:@"_nes.png"];
        NSData *png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];

        if(!png || ![png writeToFile:out atomically:YES])
        {
            fprintf(stderr, "Error: could not write '%s'.\n", out.UTF8String);
            return 1;
        }

        printf("Wrote %s%s\n", out.UTF8String, attr ? "" : " (no attributes in the nametable)");
    }
    return 0;
}
