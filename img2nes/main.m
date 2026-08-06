//
//  main.m
//  img2nes
//
//  Created by Jonatan Yde on 15/11/2023.
//

#import <Foundation/Foundation.h>
#import "Palette.h"
#import "img.h"

#define CLAMP(x, low, high)  (((x) > (high)) ? (high) : (((x) < (low)) ? (low) : (x)))

#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c"
#define BYTE_TO_BINARY(byte)  \
  ((byte) & 0x80 ? '1' : '0'), \
  ((byte) & 0x40 ? '1' : '0'), \
  ((byte) & 0x20 ? '1' : '0'), \
  ((byte) & 0x10 ? '1' : '0'), \
  ((byte) & 0x08 ? '1' : '0'), \
  ((byte) & 0x04 ? '1' : '0'), \
  ((byte) & 0x02 ? '1' : '0'), \
  ((byte) & 0x01 ? '1' : '0')


#define TILE_SIZE 8
#define ATTR_SIZE 16
#define CHR_SIZE 16
#define CHR_ROM_SIZE 8192
#define NMT_SIZE 960
#define PAL_SIZE 16
#define DEBUG_LEVEL 0


uint8_t CHR[8192];
uint8_t nametable[960];

// Baggrundens mønstertabel ligger på $1000 og rummer 256 tiles. Tile 0 holdes blank, så
// skærmen uden om billedet er ensfarvet - der er altså 255 at gøre godt med til 960 felter.
#define BACKGROUND_TILES 256
#define FIRST_TILE 1
static int allocatedTiles = FIRST_TILE;
static NSMutableDictionary<NSData *, NSNumber *> *tileIndexByPattern = nil;
static int reusedTiles = 0, approximatedTiles = 0;

// Blokkene samles op inden pladserne uddeles. Uddeler man efter først-til-moelle, bruger
// himlen oeverst i billedet alle 255 tiles, og resten maa noejes med en tilnaermelse. Ved at
// vente til alle moenstre er kendt kan de hyppigste faa pladserne, og kun de sjaeldne
// tilnaermes - det er dem det gaar mindst ud over.
#define MAX_BLOCKS 960
typedef struct { uint8_t pattern[16]; int position; } TileBlock;
static TileBlock blocks[MAX_BLOCKS];
static int blockCount = 0;

float GetDistanceBetweenColor(NSColor* a, NSColor* b);
NSColor* MatchColor(NSColor* input, NSArray* palette);
void reduceBlock(NSBitmapImageRep *image, CGRect block, NSArray* palette);
void ditherBlock(NSBitmapImageRep *sourceImage, CGRect block, NSArray* palette);
NSColor* getDominantColor(NSDictionary* palette);
NSArray* getProminentColors(NSDictionary* palette, int max);
NSArray* getReducedPalette(NSDictionary *palette, int maxColors,  NSColor* _Nullable requiredColor);
NSDictionary* getUsedColors(NSBitmapImageRep* image, CGRect block);
NSData* convertPalettes(NSArray* palettes);
NSString* convertPalettesToJSON(NSArray* palettes);
void generateAssemblyFor(NSString * file);
NSArray* importPaletteFrom(NSString *file);
NSArray *uniqueColorsInPalettes(NSArray *palettes);
NSBitmapImageRep* normalizedCopyOf(NSBitmapImageRep *source);
NSBitmapImageRep* scaledCopyOf(NSBitmapImageRep *source, NSInteger width, NSInteger height);
NSArray* choosePalettes(NSBitmapImageRep *image, int width, int height, NSColor *background);
NSArray* bestPaletteForColors(NSDictionary *colors, NSArray *palettes);
double paletteErrorForColors(NSDictionary *colors, NSArray *palette);
void printHelp(void);
static BOOL writeDataTo(NSData *data, NSString *path);
static BOOL writeTextTo(NSString *text, NSString *path);
void recordTile(const uint8_t *pattern, int position);
void assignTiles(uint8_t *nametable);

typedef enum : int {
    PatternDefault,
    PatternRandom,
    PatternInnerCross,
    PatternTopLeftSquare,
    PatternCorners,
    PatternOuterCross
} PatternSelection;


// Skriver en fil og siger til hvis det går galt. Før blev returværdien kastet væk overalt,
// så programmet kunne melde alt vel uden at have skrevet en eneste byte.
static BOOL writeDataTo(NSData *data, NSString *path)
{
    NSError *error = nil;

    if([data writeToFile:path options:NSDataWritingAtomic error:&error])
        return YES;

    fprintf(stderr, "Error: could not write '%s': %s\n", path.UTF8String,
            error.localizedDescription.UTF8String);
    return NO;
}

static BOOL writeTextTo(NSString *text, NSString *path)
{
    NSError *error = nil;

    if([text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error])
        return YES;

    fprintf(stderr, "Error: could not write '%s': %s\n", path.UTF8String,
            error.localizedDescription.UTF8String);
    return NO;
}

int main(int argc, char * argv[]) {
    @autoreleasepool {
        
//        printf("%s", argv[0]);
        NSString *inputFile;
        NSString *outputFile;
		NSString *paletteFile;
        NSString *bgColor;
        BOOL dither = NO;
        BOOL createPreview = NO;
        BOOL printAttributes = NO;
        int maxColors = 13;
        BOOL maxColorsGiven = NO;
        int verbose_level = 0;
        BOOL center = YES;      // Pænest, og uden ulemper nu hvor attributterne følger med
        BOOL fullscreen = NO;
        BOOL outputBundle = NO;
		BOOL compact = YES;
        
        int opt;
        opterr = 0;
        //Input, output, verbose, max colors, systempalette, pattern mode, background, preview, dither, center, bundle
        while ((opt = getopt (argc, argv, "i:o:v:m:s:l:g:pdctFbxh")) != -1)
            switch (opt)
        {
            case 'i':           //Input
                inputFile = [NSString stringWithFormat:@"%s", optarg];
                if(!outputFile)
                    outputFile = [inputFile stringByDeletingPathExtension];
                break;
            case 'o':           //Output
                outputFile = [NSString stringWithFormat:@"%s", optarg];
                if( outputFile.pathExtension.length !=0 )
                    outputFile = [outputFile stringByDeletingPathExtension];
                break;
			case 'l':           //Input
				paletteFile = [NSString stringWithFormat:@"%s", optarg];
				break;
            case 'm':           //Max colors
                maxColors = [[NSString stringWithFormat:@"%s", optarg] intValue];
                maxColorsGiven = YES;
                break;
            case 'p':           //Output readable formats for palette and preview
                createPreview = YES;
                printf("Write image preview\n");
                break;
            case 'g':
                bgColor = [NSString stringWithFormat:@"%s", optarg];
                break;
            case 'd':        //dither
                dither = YES;
                break;
			case 'x':        //compact
				compact = NO;
				break;
            case 'b':        //bundle?
                outputBundle = YES;
                break;
            case 'h':           //Help
                printHelp();
                return 0;
            case 'c':           // Centrering er nu standard. Flaget beholdes så ældre
                center = YES;       // kommandolinjer stadig virker.
                break;
            case 't':           //Anchor at the top left instead of centring
                center = NO;
                break;
            case 'F':           //Fullscreen: scale to 256x240 and keep the tile count down
                fullscreen = YES;   // Dither er slået fra i forvejen; sættes den ikke her,
                break;              // bliver -d -F og -F -d ens.
            case 'v':           //Verbose level 0-3
                verbose_level = atoi(optarg);
                break;
            case 's':
                switch( [[NSString stringWithFormat:@"%s", optarg] intValue] )
                {
                    case 0:
                        [[Palette sharedPalette] shiftSystemPalette:0 ];
                        printf("Using MESEN default palette\n");
                        break;
                    case 1:
                        [[Palette sharedPalette] shiftSystemPalette:1 ];
                        printf("Using FCEUX default palette\n");
                        break;
                    case 2:
                        [[Palette sharedPalette] shiftSystemPalette:2 ];
                        printf("Using errorneous palette\n");
                        break;
                    default:
                        [[Palette sharedPalette] shiftSystemPalette:0 ];
                        printf("Using MESEN default palette\n");
                        break;
                }
                break;
            case '?':
                if (optopt == 'i' )
                    fprintf (stderr, "Option -%c requires an argument.\n", optopt);
                else if (isprint (optopt))
                    fprintf (stderr, "Unknown option `-%c'.\n", optopt);
                else
                    fprintf (stderr,
                             "Unknown option character `\\x%x'.\n",
                             optopt);
                return 1;
            default:
                abort ();
        }
        
        if(!inputFile)
        {
            printf("Error: no input file!\n");
            printf("Usage: img2nes -i <file> <options>\n");
            printf("use -h to see all options.\n");
            return 1;
        }
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:inputFile])
        {
            printf("Error: Input file not found.\n");
            return 1;
        }
        
        
        if(verbose_level > 1)
            printAttributes = YES;
        

        NSData *inputData = [NSData dataWithContentsOfFile:inputFile];
        NSImage *inputImage = [[NSImage alloc] initWithData:inputData];
        NSBitmapImageRep *sourceRep = [NSBitmapImageRep imageRepWithData:[inputImage TIFFRepresentation]];

        if(!sourceRep)
        {
            printf("Error: '%s' could not be read as an image.\n", inputFile.UTF8String);
            return 1;
        }

        // Gråtone-, indekserede og 16-bit billeder kan ikke læses med colorAtX:y: og
        // redComponent - de kaster. Billedet tegnes derfor om til et kendt RGB-format.
        // -F strækker billedet til hele skærmen uanset sideforhold, og skruer samtidig ned
        // for farverne: færre farver giver færre forskellige tiles, og det er netop
        // tilnærmelserne der ødelægger et fuldskærmsbillede.
        NSBitmapImageRep *inputRep = fullscreen ? scaledCopyOf(sourceRep, 256, 240)
                                                : normalizedCopyOf(sourceRep);

        if(fullscreen && !maxColorsGiven)
            maxColors = 4;

        if(!inputRep)
        {
            printf("Error: the image format of '%s' is not supported.\n", inputFile.UTF8String);
            return 1;
        }

        if(inputRep.pixelsWide > 256)
        {
            printf("Input width larger than 256\n");
            return 1;
        }

        if(inputRep.pixelsHigh > 240)
        {
            printf("Input height larger than 240\n");
            return 1;
        }

        if((int)inputRep.pixelsWide % 8 != 0)
        {
            printf("Input width must be divisible with 8\n");
            return 1;
        }

        if((int)inputRep.pixelsHigh % 8 != 0)
        {
            // Uden det her læses der pixels neden for billedet i den nederste blok
            printf("Input height must be divisible with 8\n");
            return 1;
        }
        
        int width = (int)inputRep.pixelsWide;
        int height = (int)inputRep.pixelsHigh;
        // Attributtabellens kvadranter dækker 16x16 pixels. Lander billedet på et ulige antal
        // tiles, ligger dets 16x16-blokke hen over to kvadranter, og så kan paletterne ikke
        // sættes rigtigt uanset hvad. Forskydningen rundes derfor ned til et lige antal tiles.
        // Uden centrering ligger billedet i øverste venstre hjørne, og så skal forskydningen
        // være nul begge steder - både for nametablen og for attributterne.
        int xOffset = center ? (((int)((256 - width) / 2) / 8) & ~1) : 0;
        int yOffset = center ? (((int)((240 - height) / 2) / 8) & ~1) : 0;
        int nmt_offset = 0;
        int attr_column = 0;
        int attr_offset = 0;
        int attr_pos = 0;
        
        if(center)
        {
            nmt_offset = yOffset * 32 + xOffset;
            attr_column = xOffset / 4;
            attr_offset = (yOffset/4) * 8 + (xOffset/4);
            attr_pos = (xOffset % 4);
            printf("Centering image\n");
            //printf("For the time being centering only supports one palette.\nMax colors have been reduced to 4\n");
            // maxColors = 4;
        }
                        
        if(dither)
        {
            printf("Using dithering to reduce colors  to NES colors.\n");
            ditherBlock(inputRep, CGRectMake(0, 0, width, height), [[Palette sharedPalette] NESpalette].allValues);
        }
        else
        {
            printf("Using closest match to reduce colors to NES colors.\n");
            reduceBlock(inputRep, CGRectMake(0, 0, width, height), [[Palette sharedPalette] NESpalette].allValues);
        }
        
        CGRect imgRect = CGRectMake(0, 0, width, height);
        
        NSDictionary *allColors = getUsedColors(inputRep, imgRect);
        printf("NES colors used in original: %lu\n", allColors.count);

		
		//TODO: Manually define background color
				
        NSColor *dominantColor = getDominantColor(allColors);
        if(bgColor)
        {
            // Brugte før altid $00 uanset hvad der stod efter -g
            NSString *name = [bgColor hasPrefix:@"$"] ? bgColor.uppercaseString : [@"$" stringByAppendingString:bgColor.uppercaseString];
            NSColor *chosen = [[Palette sharedPalette] getColorFromName:name];

            if(!chosen)
            {
                printf("Error: '%s' is not a NES color. Use a name like $0F.\n", bgColor.UTF8String);
                return 1;
            }

            dominantColor = chosen;
        }
        printf("%s is the dominant color and therefor candidate as background\n", [[[Palette sharedPalette] getNameFromColor:dominantColor] cStringUsingEncoding:NSUTF8StringEncoding]);
		
		
		NSArray *selectedColors;
		NSMutableArray *palettes;
		if(paletteFile) {
			palettes = (NSMutableArray*) importPaletteFrom(paletteFile);

			if(!palettes)
				return 1;

			dominantColor = [[palettes firstObject] firstObject];
			selectedColors = uniqueColorsInPalettes(palettes);
			printf("Custom palette contains %lu unique colors\n", (unsigned long)selectedColors.count );
			printf("%s will be used as background\n", [[[Palette sharedPalette] getNameFromColor:dominantColor] cStringUsingEncoding:NSUTF8StringEncoding]);

		} else {
			selectedColors = getReducedPalette(allColors, maxColors, dominantColor); // getProminentColors(allColors, 13);
		}

        reduceBlock(inputRep, CGRectMake(0, 0, width, height), selectedColors);
        
        NSDictionary *used = getUsedColors(inputRep, imgRect);
        printf("Using %lu colors from the NES palette\n", used.count );
                

		if(!palettes)
			palettes = (NSMutableArray *) choosePalettes(inputRep, width, height, dominantColor);
        
        int nmtPosition = nmt_offset;
        
        int pc = attr_pos, attrByte = attr_offset;
        
        uint8_t attributes[64];
        memset(&attributes, 0x00, 64);

        for(int row = 0; row < inputRep.pixelsHigh; row+=16)
        {
            for(int column = 0; column < inputRep.pixelsWide; column+=16)
            {
                CGRect activeSquare = CGRectMake(column, row, 16, 16);
                NSDictionary *activeColors = getUsedColors(inputRep, activeSquare );
                
                // Vælg den palette der giver mindst samlet afvigelse for blokkens pixels.
                // Før blev der talt hvor mange farver der var ens, hvilket ikke tager højde
                // for hvor stor en del af blokken hver farve fylder.
                NSArray *activePalette = bestPaletteForColors(activeColors, palettes);
                
                reduceBlock(inputRep, activeSquare, activePalette);

                
                nmtPosition = nmt_offset + (row/8) * 32 + (column/8);
                int nmtRow = (nmtPosition / 64);

                int paletteIndex = (int)[palettes indexOfObject:activePalette];

                // Samme formel som hardwaren bruger: én byte per 32x32 pixels, fire kvadranter
                // à 16x16 i hver. Før blev attrByte og pc bogført undervejs og kom ud af trit
                // så snart billedet ikke lå i skærmens øverste venstre hjørne.
                {
                    int nx = xOffset + column/8;
                    int ny = yOffset + row/8;

                    if(nx < 32 && ny < 30)
                    {
                        int quadrant = ((ny % 4) / 2) * 2 + ((nx % 4) / 2);
                        attributes[(ny/4)*8 + (nx/4)] |= (paletteIndex << (quadrant*2));
                    }
                }
                

                if(column + 16 >= width) //(column == 0 & row > 0)
                {
                    if((nmtRow) % 2 == 0)   // == 0)
                    {
                        pc = (attr_pos != 0 ? attr_pos%2 : 2);
                        attrByte -= (attrByte % 8);
                        attrByte += attr_column;
                        
                    } else {
                        pc = (attr_pos != 0 ? attr_pos : 0);
                        attrByte += 8 -(attrByte % 8);
                        attrByte += attr_column;
                    }
                }
                else if(pc % 2 == 0)
                {
                    if((nmtRow) % 2 == 1)
                    {
                        pc = 2;
                    } else {
                        pc = 0;
                    }
                    attrByte++;
                }
                
                //Convert pixel data to chr data
                for(int i = 0; i<4; i++)
                {
                    uint8_t pattern[16];

                    for(int y = 0; y < 8; y++)
                    {
                        uint8_t upper = 0;
                        uint8_t lower = 0;
                        
                        for(int x = 0; x< 8; x++)
                        {
                            NSColor *color = [inputRep colorAtX:column+x y: row+y];
                            color = MatchColor(color, activePalette);
                            long index = [activePalette indexOfObject:color];

                            upper |= ((index & 1) << (7-x));
                            lower |= ((index >> 1) << (7-x));
                        }

                        pattern[y] = upper;
                        pattern[y+8] = lower;
                    }

                    nmtPosition = nmt_offset + (row/8) * 32 + (column/8);

                    // Selve uddelingen sker først når alle blokke er kendt, se assignTiles.
                    if(nmtPosition >= 0 && nmtPosition < NMT_SIZE)
                        recordTile(pattern, nmtPosition);

                    //Calculate next positon, index and offsets
                    column += 8;
                    if(column % 16 == 0)
                    {
                        column -= 16;
                        row += 8;
                        if(row % 16 == 0)
                        {
                            row-=16;
                        }
                    }
                }
                
            }
        }
        

        assignTiles(nametable);

        printf("Tiles: %d of %d used, %d blocks reused an existing tile", allocatedTiles - FIRST_TILE, BACKGROUND_TILES - FIRST_TILE, reusedTiles);
        if(approximatedTiles > 0)
            printf(", %d had to settle for the closest match", approximatedTiles);
        printf("\n");

        // Over en tredjedel tilnærmede blokke ses tydeligt. Målt: ar.jpg 0%, cb.jpg 11% (fin),
        // candy.png 56% (den Jonatan er mindst tilfreds med).
        if(blockCount > 0 && approximatedTiles * 100 / blockCount > 30)
        {
            fflush(stdout);     // ellers står advarslen før den linje den handler om
            fprintf(stderr, "Warning: due to high variation in the required tiles, the result "
                            "might not be satisfactory (%d%% of the blocks had to settle for "
                            "the closest match).\n", approximatedTiles * 100 / blockCount);

            // Kun de råd der faktisk kan følges. Under -F er farverne allerede skruet ned,
            // og "gør billedet mindre" modsiger hele pointen med flaget.
            BOOL advised = NO;

            if(dither)
            {
                fprintf(stderr, "         Try again without -d.\n");
                advised = YES;
            }

            if(maxColors > 6)
            {
                fprintf(stderr, "         Lower the colour count with -m (for example -m 6).\n");
                advised = YES;
            }

            if(!fullscreen)
            {
                fprintf(stderr, "         A smaller image leaves fewer tiles to approximate.\n");
                advised = YES;
            }

            if(!advised)
                fprintf(stderr, "         This image asks for more distinct tiles than the NES "
                                "can hold; there is no setting that fixes it.\n");
        }

        printf("Palettes used: %lu\n", (unsigned long)palettes.count);
        while(palettes.count < 4)
        {
            [palettes addObject: [palettes lastObject]];
        }
        NSError *err;

        if(createPreview)
        {
            NSData *pngData = [inputRep representationUsingType: NSBitmapImageFileTypePNG properties: @{}];
            [pngData writeToFile: [[outputFile stringByAppendingString:@"_preview"] stringByAppendingPathExtension:@"png"]  options:NSDataWritingAtomic error:&err];
            
            if(verbose_level > 0)
                return 1;
        }
        
        
        NSData* chrData = [NSData dataWithBytes:CHR length:8192];
        NSData* nmtData = [NSData dataWithBytes:nametable length:960];
        NSData* attrData = [NSData dataWithBytes:attributes length:64];
        
        BOOL written = YES;

        if(!outputBundle)
        {
			if(!writeDataTo(chrData, [outputFile stringByAppendingPathExtension:@"chr"])) written = NO;
			if(!writeDataTo(nmtData, [outputFile stringByAppendingPathExtension:@"nmt"])) written = NO;
			NSData* palData = convertPalettes(palettes);
			if(!writeDataTo(palData, [outputFile stringByAppendingPathExtension:@"pal"])) written = NO;
			NSString *code = asm;
			
			
			if(!compact)
			{
				if(!writeDataTo(attrData, [outputFile stringByAppendingPathExtension:@"attr"])) written = NO;
				code = [code stringByReplacingOccurrencesOfString:@";;[@]" withString: @".incbin \"[$name].attr\""];
			}
			else
			{
				NSString *nmtPath = [outputFile stringByAppendingPathExtension:@"nmt"];
				NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:nmtPath];

				// Slog nmt-skrivningen fejl, er handle nil, og attributterne forsvandt tavst
				if(!handle)
				{
					fprintf(stderr, "Error: could not append the attributes to '%s'.\n", nmtPath.UTF8String);
					written = NO;
				}
				else
				{
					[handle seekToEndOfFile];
					[handle writeData:attrData];
					[handle closeFile];
				}

				code = [code stringByReplacingOccurrencesOfString:@";;[@]" withString: @""];
			}
			

			code = [code stringByReplacingOccurrencesOfString:@"[$name]" withString: outputFile.lastPathComponent];
			if(!writeTextTo(code, [outputFile stringByAppendingPathExtension:@"asm"])) written = NO;
        }
        else
        {
            outputFile = [outputFile stringByAppendingPathExtension:@"nesgfx"];
            NSError *dirError = nil;

            // withIntermediateDirectories:NO fejler med "file exists" når bundlet findes i
            // forvejen. Fejlen blev brugt som betingelse for hele skrivningen nedenfor, så
            // anden kørsel med samme navn lod det gamle billede blive liggende - uden et ord.
            // Med YES lykkes kaldet både for en ny og en eksisterende mappe.
            if([[NSFileManager defaultManager] createDirectoryAtPath:outputFile
                                         withIntermediateDirectories:YES
                                                          attributes:nil
                                                               error:&dirError])
            {
                NSString* palJson = convertPalettesToJSON(palettes);
                if(!writeTextTo(palJson, [outputFile stringByAppendingPathComponent:@"palette.nespal"])) written = NO;

                if(!writeDataTo(nmtData, [outputFile stringByAppendingPathComponent:@"nametable.nmt"])) written = NO;
                if(!writeDataTo(chrData, [outputFile stringByAppendingPathComponent:@"tiles.chr"])) written = NO;
                if(!writeDataTo(attrData, [outputFile stringByAppendingPathComponent:@"attributes.attr"])) written = NO;

                
                NSDictionary *projectFiles = @{
                    @"nametable" :  @"nametable.nmt",
                    @"chrrom" :  @"tiles.chr",
                    @"palette" : @"palette.nespal",
                    @"attributes" : @"attributes.attr"
                };
                NSData *projData = [NSJSONSerialization dataWithJSONObject:projectFiles options:NSJSONWritingPrettyPrinted | NSJSONWritingWithoutEscapingSlashes error:&dirError];
                if(!writeDataTo(projData, [outputFile stringByAppendingPathComponent:@"project.nesproj"])) written = NO;
            }
            else
            {
                fprintf(stderr, "Error: could not create '%s': %s\n", outputFile.UTF8String,
                        dirError.localizedDescription.UTF8String);
                written = NO;
            }
        }
            
        if(printAttributes)
        {
            printf("Attributes:\n.db ");
            for(int i = 0; i < 64; i++)
            {
                
                if(i % 8 == 0 && i > 0)
                    printf("\n.db ");
                printf("%%"BYTE_TO_BINARY_PATTERN", ", BYTE_TO_BINARY(attributes[i]));
            }
            printf("\n");
        }

        if(!written)
            return 1;
    }
    return 0;
}



#pragma mark Palette selection

// Hvor dårligt en palette dækker en blok: hver farve vejer med hvor mange pixels den fylder,
// og koster afstanden til den nærmeste farve paletten faktisk har.
double paletteErrorForColors(NSDictionary *colors, NSArray *palette)
{
    double error = 0;

    for (NSColor *color in colors)
    {
        int count = [[colors objectForKey:color] intValue];
        float best = FLT_MAX;

        for (NSColor *candidate in palette)
        {
            float distance = GetDistanceBetweenColor(color, candidate);
            if(distance < best)
                best = distance;
        }

        error += sqrt(best) * count;
    }

    return error;
}

NSArray* bestPaletteForColors(NSDictionary *colors, NSArray *palettes)
{
    NSArray *best = [palettes firstObject];
    double bestError = DBL_MAX;

    for (NSArray *palette in palettes)
    {
        double error = paletteErrorForColors(colors, palette);

        if(error < bestError)
        {
            bestError = error;
            best = palette;
        }
    }

    return best;
}

// De tre hyppigste farver i en optælling, bortset fra baggrunden
static NSArray* topColorsExcluding(NSDictionary *colors, NSColor *background, int wanted)
{
    NSMutableArray *candidates = [[colors allKeys] mutableCopy];
    [candidates removeObject:background];

    [candidates sortUsingComparator:^NSComparisonResult(NSColor *a, NSColor *b) {
        return [[colors objectForKey:b] compare:[colors objectForKey:a]];
    }];

    if(candidates.count > wanted)
        [candidates removeObjectsInRange:NSMakeRange(wanted, candidates.count - wanted)];

    return candidates;
}

// Vælger de fire paletter ud fra hele billedet i stedet for fire tilfældige felter.
// Først et bud ud fra de hyppigste farvekombinationer, derefter et par gennemløb hvor hver
// blok tildeles den palette der passer bedst, og hver palette tilpasses sine egne blokke.
NSArray* choosePalettes(NSBitmapImageRep *image, int width, int height, NSColor *background)
{
    NSMutableArray *blocks = [[NSMutableArray alloc] init];

    for(int row = 0; row + 16 <= height; row += 16)
        for(int column = 0; column + 16 <= width; column += 16)
            [blocks addObject: getUsedColors(image, CGRectMake(column, row, 16, 16))];

    if(blocks.count == 0)
        return nil;

    // Første bud: de hyppigst forekommende trefarve-kombinationer blandt blokkene
    NSCountedSet *combinations = [[NSCountedSet alloc] init];
    for (NSDictionary *block in blocks)
    {
        NSArray *top = topColorsExcluding(block, background, 3);
        if(top.count > 0)
            [combinations addObject:top];
    }

    NSArray *ranked = [[combinations allObjects] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        return [@([combinations countForObject:b]) compare:@([combinations countForObject:a])];
    }];

    NSMutableArray *palettes = [[NSMutableArray alloc] init];
    for (NSArray *combination in ranked)
    {
        if(palettes.count == 4)
            break;

        NSMutableArray *palette = [[NSMutableArray alloc] initWithObjects:background, nil];
        [palette addObjectsFromArray:combination];

        while(palette.count < 4)
            [palette addObject: [palette lastObject]];

        [palettes addObject:palette];
    }

    while(palettes.count < 4)
        [palettes addObject: [palettes lastObject] ?: @[background, background, background, background]];

    // Forbedr dem: tildel blokke, tilpas paletter, gentag
    for(int pass = 0; pass < 4; pass++)
    {
        NSMutableArray *assigned = [[NSMutableArray alloc] init];
        for(int i = 0; i < 4; i++)
            [assigned addObject: [[NSMutableDictionary alloc] init]];

        for (NSDictionary *block in blocks)
        {
            NSArray *palette = bestPaletteForColors(block, palettes);
            NSMutableDictionary *bucket = [assigned objectAtIndex: [palettes indexOfObject:palette]];

            for (NSColor *color in block)
            {
                NSNumber *count = [bucket objectForKey:color];
                [bucket setObject:@([count intValue] + [[block objectForKey:color] intValue]) forKey:color];
            }
        }

        for(int i = 0; i < 4; i++)
        {
            NSDictionary *bucket = [assigned objectAtIndex:i];
            if(bucket.count == 0)
                continue;

            NSMutableArray *palette = [[NSMutableArray alloc] initWithObjects:background, nil];
            [palette addObjectsFromArray: topColorsExcluding(bucket, background, 3)];

            while(palette.count < 4)
                [palette addObject: [palette lastObject]];

            [palettes replaceObjectAtIndex:i withObject:palette];
        }
    }

    return palettes;
}

#pragma mark Tile reuse


// Gemmer en blok til senere. Selve tildelingen kan foerst ske naar alle er kendt.
void recordTile(const uint8_t *pattern, int position)
{
    if(blockCount >= MAX_BLOCKS)
        return;

    memcpy(blocks[blockCount].pattern, pattern, 16);
    blocks[blockCount].position = position;
    blockCount++;
}

// Pakker mellem NES' to bitplaner og en enkel liste med 64 pixelvaerdier 0-3, som er
// nemmere at regne gennemsnit paa.
static void unpackTile(const uint8_t *pattern, uint8_t *pixels)
{
    for(int y = 0; y < 8; y++)
        for(int x = 0; x < 8; x++)
        {
            int bit = 7 - x;
            pixels[y*8 + x] = ((pattern[y] >> bit) & 1) | (((pattern[y+8] >> bit) & 1) << 1);
        }
}

static void packTile(const uint8_t *pixels, uint8_t *pattern)
{
    memset(pattern, 0, 16);

    for(int y = 0; y < 8; y++)
        for(int x = 0; x < 8; x++)
        {
            int bit = 7 - x, value = pixels[y*8 + x];
            pattern[y]   |= (value & 1) << bit;
            pattern[y+8] |= ((value >> 1) & 1) << bit;
        }
}

static int pixelDistance(const uint8_t *a, const uint8_t *b)
{
    int distance = 0;

    for(int i = 0; i < 64; i++)
        distance += abs(a[i] - b[i]);

    return distance;
}

// Uddeler de 255 tiles og skriver nametablen.
//
// Et foto bruger naesten kun moenstre der optraeder en enkelt gang - paa candy.png er 67% af
// dem unikke, paa portraetter over 90%. Derfor nytter det ikke at uddele pladserne til de
// hyppigste og lade resten finde det naermeste: opgaven er at vaelge 255 *repraesentanter*
// blandt de 500-700 moenstre billedet beder om. Det er samme problem som ved paletterne, og
// loesningen er den samme - Lloyds algoritme, her paa pixelvaerdier i stedet for farver.
// Afstanden er summen af forskelle, saa den rigtige midte er medianen, ikke gennemsnittet.
void assignTiles(uint8_t *nametable)
{
    if(blockCount == 0)
        return;

    NSMutableDictionary<NSData *, NSNumber *> *counts = [NSMutableDictionary dictionary];

    for(int i = 0; i < blockCount; i++)
    {
        NSData *key = [NSData dataWithBytes:blocks[i].pattern length:16];
        counts[key] = @(counts[key].intValue + 1);
    }

    // Hyppigst foerst. Ved lige mange sammenlignes selve moenstret, saa to koersler paa samme
    // billede altid giver den samme fil.
    NSArray<NSData *> *ordered = [counts.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSData *a, NSData *b) {
        int countA = counts[a].intValue, countB = counts[b].intValue;

        if(countA != countB)
            return countA > countB ? NSOrderedAscending : NSOrderedDescending;

        int order = memcmp(a.bytes, b.bytes, 16);
        return order < 0 ? NSOrderedAscending : (order > 0 ? NSOrderedDescending : NSOrderedSame);
    }];

    int distinctCount = (int)ordered.count;
    int slots = MIN(distinctCount, BACKGROUND_TILES - FIRST_TILE);

    uint8_t (*pixels)[64] = calloc(distinctCount, 64);
    uint8_t (*center)[64] = calloc(slots, 64);
    uint8_t (*best)[64]   = calloc(slots, 64);
    int *weight = calloc(distinctCount, sizeof(int));
    int *nearest = calloc(distinctCount, sizeof(int));

    if(!pixels || !center || !best || !weight || !nearest)
    {
        free(pixels); free(center); free(best); free(weight); free(nearest);
        fprintf(stderr, "Out of memory while choosing tiles\n");
        return;
    }

    NSMutableDictionary<NSData *, NSNumber *> *rowForPattern = [NSMutableDictionary dictionary];

    for(int i = 0; i < distinctCount; i++)
    {
        unpackTile(ordered[i].bytes, pixels[i]);
        weight[i] = counts[ordered[i]].intValue;
        rowForPattern[ordered[i]] = @(i);
    }

    // Start med de hyppigste og lad dem flytte sig derhen hvor de daekker bedst.
    for(int c = 0; c < slots; c++)
        memcpy(center[c], pixels[c], 64);

    long bestError = LONG_MAX;

    for(int pass = 0; pass < 8; pass++)
    {
        long error = 0;
        int worst = 0; long worstDistance = -1;

        for(int i = 0; i < distinctCount; i++)
        {
            int pick = 0, pickDistance = INT_MAX;

            for(int c = 0; c < slots; c++)
            {
                int distance = pixelDistance(pixels[i], center[c]);

                if(distance < pickDistance)
                {
                    pickDistance = distance;
                    pick = c;

                    if(distance == 0)
                        break;
                }
            }

            nearest[i] = pick;
            error += (long)pickDistance * weight[i];

            if((long)pickDistance * weight[i] > worstDistance)
            {
                worstDistance = (long)pickDistance * weight[i];
                worst = i;
            }
        }

        if(error < bestError)
        {
            bestError = error;
            memcpy(best, center, (size_t)slots * 64);
        }

        if(pass == 7 || bestError == 0)
            break;

        // Ny midte: den vaegtede median af medlemmernes pixelvaerdier.
        for(int c = 0; c < slots; c++)
        {
            int histogram[64][4];
            memset(histogram, 0, sizeof(histogram));
            long members = 0;

            for(int i = 0; i < distinctCount; i++)
            {
                if(nearest[i] != c)
                    continue;

                members += weight[i];

                for(int px = 0; px < 64; px++)
                    histogram[px][pixels[i][px]] += weight[i];
            }

            if(members == 0)
            {
                // Ingen bruger denne plads - giv den til det moenster der passer daarligst.
                memcpy(center[c], pixels[worst], 64);
                worstDistance = -1;
                continue;
            }

            for(int px = 0; px < 64; px++)
            {
                long half = members / 2, running = 0;
                int value = 3;

                for(int v = 0; v < 4; v++)
                {
                    running += histogram[px][v];

                    if(running > half)
                    {
                        value = v;
                        break;
                    }
                }

                center[c][px] = (uint8_t)value;
            }
        }
    }

    // Skriv de valgte tiles og find den endelige plads til hvert moenster.
    for(int c = 0; c < slots; c++)
        packTile(best[c], CHR + 4096 + (FIRST_TILE + c)*16);

    allocatedTiles = FIRST_TILE + slots;

    int *tileForPattern = calloc(distinctCount, sizeof(int));

    if(!tileForPattern)
    {
        free(pixels); free(center); free(best); free(weight); free(nearest);
        fprintf(stderr, "Out of memory while choosing tiles\n");
        return;
    }

    for(int i = 0; i < distinctCount; i++)
    {
        int pick = 0, pickDistance = INT_MAX;

        for(int c = 0; c < slots; c++)
        {
            int distance = pixelDistance(pixels[i], best[c]);

            if(distance < pickDistance)
            {
                pickDistance = distance;
                pick = c;

                if(distance == 0)
                    break;
            }
        }

        tileForPattern[i] = FIRST_TILE + pick;

        if(pickDistance == 0)
            reusedTiles += weight[i] - 1;
        else
            approximatedTiles += weight[i];
    }

    for(int i = 0; i < blockCount; i++)
    {
        NSData *key = [NSData dataWithBytes:blocks[i].pattern length:16];
        nametable[blocks[i].position] = (uint8_t)tileForPattern[rowForPattern[key].intValue];
    }

    free(pixels); free(center); free(best); free(weight); free(nearest); free(tileForPattern);
}

#pragma mark Input

// Tegner et vilkårligt bitmap om til 8-bit RGB, så colorAtX:y: og redComponent altid er lovlige
NSBitmapImageRep* normalizedCopyOf(NSBitmapImageRep *source)
{
    return scaledCopyOf(source, source.pixelsWide, source.pixelsHigh);
}

// Samme omtegning, men til en valgt størrelse. Sideforholdet bevares bevidst ikke - et
// fotos rammer betyder mindre end at fylde skærmen ud.
NSBitmapImageRep* scaledCopyOf(NSBitmapImageRep *source, NSInteger width, NSInteger height)
{
    if(width < 1 || height < 1)
        return nil;

    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                    pixelsWide:width
                                                                    pixelsHigh:height
                                                                 bitsPerSample:8
                                                               samplesPerPixel:4
                                                                      hasAlpha:YES
                                                                      isPlanar:NO
                                                                colorSpaceName:NSCalibratedRGBColorSpace
                                                                   bytesPerRow:0
                                                                  bitsPerPixel:0];
    if(!rep)
        return nil;

    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
    if(!context)
        return nil;

    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    context.imageInterpolation = NSImageInterpolationHigh;
    [source drawInRect:NSMakeRect(0, 0, width, height)];
    [NSGraphicsContext restoreGraphicsState];

    return rep;
}

void printHelp(void)
{
    printf("img2nes - convert an image to NES background graphics\n\n");
    printf("Usage: img2nes -i <file> [options]\n\n");
    printf("  -i <file>   Input image. Max 256x240, both sides divisible by 8 (see -F).\n");
    printf("              The image is centred on the screen; use -t to anchor it top left.\n");
    printf("  -o <name>   Output name without extension. Defaults to the input name.\n");
    printf("  -t          Anchor the image at the top left instead of centring it.\n");
    printf("  -F          Fullscreen: scale the image to 256x240 regardless of its\n");
    printf("              aspect ratio, without dithering and with fewer colours.\n");
    printf("  -d          Dither instead of picking the closest colour.\n");
    printf("  -m <n>      Maximum number of NES colours to reduce to (default 13).\n");
    printf("  -g <$xx>    NES colour to use as background, e.g. -g $0F.\n");
    printf("  -l <file>   Load a 16-byte binary palette instead of choosing one.\n");
    printf("  -s <0-2>    System palette: 0 Mesen, 1 FCEUX, 2 legacy.\n");
    printf("  -b          Write a .nesgfx project bundle instead of separate files.\n");
    printf("  -x          Write attributes as a separate .attr file rather than appending\n");
    printf("              them to the nametable.\n");
    printf("  -p          Also write a PNG preview of the reduced image.\n");
    printf("  -v <0-3>    Verbosity. 2 or higher prints the attribute table.\n");
    printf("  -h          This help.\n");
}

#pragma mark Assembly file export
void generateAssemblyFor(NSString *file)
{
    NSString *code = asm;
    NSError *err;
    code = [code stringByReplacingOccurrencesOfString:@"[$name]" withString: file];
    [code writeToFile:[file stringByAppendingPathExtension:@"asm"] atomically:YES encoding: NSUTF8StringEncoding error:&err];
}


#pragma mark Color reduction (palette)

NSColor* getDominantColor(NSDictionary* palette)
{
    NSArray *keys = [palette keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber * obj2) {
        return obj1.intValue < obj2.intValue;
    }];
    
    return [keys firstObject];
}

NSArray* getReducedPalette(NSDictionary *palette, int maxColors,  NSColor* _Nullable requiredColor)
{
    NSMutableArray* reducedPalette = [[NSMutableArray alloc] init];
    
    NSArray *keys = [palette keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber * obj2) {
        return obj1.intValue < obj2.intValue;
    }];
        
    if(keys.count > maxColors)
        [reducedPalette addObjectsFromArray: [keys subarrayWithRange:NSMakeRange(0, maxColors)]];
    else
        [reducedPalette addObjectsFromArray:keys];
    
    
    if(requiredColor)
    {
        if(![reducedPalette doesContain:requiredColor])
        {
            if(reducedPalette.count == maxColors)
                [reducedPalette removeLastObject];
            [reducedPalette insertObject: requiredColor atIndex:0];
        }
        else if([reducedPalette indexOfObject:requiredColor] != 0)
        {
            [reducedPalette removeObject:requiredColor];
            [reducedPalette insertObject:requiredColor atIndex:0];
        }
        
    }
    
//    while(reducedPalette.count < maxColors)
//        [reducedPalette addObject: [reducedPalette lastObject]];
    
    return reducedPalette;
}

NSArray* getProminentColors(NSDictionary* palette, int max)
{
    
    NSArray *keys = [palette keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber * obj2) {
        return obj1.intValue < obj2.intValue;
    }];
    
    if(keys.count < max)
        return keys;
    else
        return [keys subarrayWithRange:NSMakeRange(0, max)];
}

#pragma mark Color reduction (image)
void reduceBlock(NSBitmapImageRep *image, CGRect block, NSArray* palette)
{
    for(int y = block.origin.y; y < block.origin.y+block.size.height; y++)
    {
        for(int x = block.origin.x; x < block.origin.x + block.size.width; x++)
        {
            NSColor *color = [image colorAtX:x y:y];

            NSColor *matchedColor = MatchColor(color, palette);
            [image setColor:matchedColor atX:x y:y];
        }
    }
}

NSDictionary* getUsedColors(NSBitmapImageRep* image, CGRect block)
{
	NSMutableDictionary* activeColors = [[NSMutableDictionary alloc] init];
	
	for(int y = block.origin.y; y < block.origin.y+block.size.height; y++)
	{
		for(int x = block.origin.x; x < block.origin.x + block.size.width; x++)
		{
			NSColor *color = [image colorAtX:x y:y];
			if(!color) continue;
			
			NSNumber *currentCount = [activeColors objectForKey:color];
			currentCount = [NSNumber numberWithInt:[currentCount intValue] + 1];
			
			[activeColors setObject:currentCount forKey:color];
		}
	}
	return [NSDictionary dictionaryWithDictionary: activeColors];
}

void ditherBlock(NSBitmapImageRep *sourceImage, CGRect block, NSArray* palette)
{
    for (int y = block.origin.y; y < block.origin.y+block.size.height; y++)
    {
        for (int x = block.origin.x; x < block.origin.x+block.size.width; x++)
        {
            NSColor *actualColor = [sourceImage colorAtX:x y:y];
            NSColor *matchedColor = MatchColor(actualColor, palette);
            
            float rError = (actualColor.redComponent - matchedColor.redComponent) / 16;
            float gError = (actualColor.greenComponent - matchedColor.greenComponent) / 16;
            float bError = (actualColor.blueComponent - matchedColor.blueComponent) / 16;
            
            [sourceImage setColor:matchedColor atX:x y:y];
            
            /*
             multiplication coeficients for surrounding pixels
               x 7
             3 5 1
             */
            
            // Fejlen spredes til naboer der kan ligge uden for billedet
            int maxX = (int)sourceImage.pixelsWide - 1;
            int maxY = (int)sourceImage.pixelsHigh - 1;

            NSColor *nextColor;
            int coefficient;
            //field to the immidiate right
            if(x+1 <= maxX)
            {
            nextColor = [sourceImage colorAtX:x+1 y:y];
            coefficient = 7;
            
            NSColor *adjustedColor = [NSColor colorWithCalibratedRed:CLAMP( nextColor.redComponent + rError * coefficient, 0, 1) green:CLAMP( nextColor.greenComponent + gError * coefficient, 0, 1) blue:CLAMP( nextColor.blueComponent + bError * coefficient, 0, 1) alpha:1.0 ];
            [sourceImage setColor:adjustedColor atX:x+1 y:y];
            }

            //field to the left & down
            if(x-1 >= 0 && y+1 <= maxY)
            {
            nextColor =  [sourceImage colorAtX:x-1 y:y+1];
            coefficient = 3;
            NSColor *adjusted = [NSColor colorWithCalibratedRed:CLAMP( nextColor.redComponent + rError * coefficient, 0, 1) green:CLAMP( nextColor.greenComponent + gError * coefficient, 0, 1) blue:CLAMP( nextColor.blueComponent + bError * coefficient, 0, 1) alpha:1.0 ];
            [sourceImage setColor:adjusted atX:x-1 y:y+1];
            }

            //field to the imidiate down
            if(y+1 <= maxY)
            {
            nextColor = [sourceImage colorAtX:x y:y+1];
            coefficient = 5;
            NSColor *adjusted = [NSColor colorWithCalibratedRed:CLAMP( nextColor.redComponent + rError * coefficient, 0, 1) green:CLAMP( nextColor.greenComponent + gError * coefficient, 0, 1) blue:CLAMP( nextColor.blueComponent + bError * coefficient, 0, 1) alpha:1.0 ];
            [sourceImage setColor:adjusted atX:x y:y+1];
            }

            //field to the right & down
            if(x+1 <= maxX && y+1 <= maxY)
            {
            nextColor = [sourceImage colorAtX:x+1 y:y+1];
            coefficient = 1;
            NSColor *adjusted = [NSColor colorWithCalibratedRed:CLAMP( nextColor.redComponent + rError * coefficient, 0, 1) green:CLAMP( nextColor.greenComponent + gError * coefficient, 0, 1) blue:CLAMP( nextColor.blueComponent + bError * coefficient, 0, 1) alpha:1.0 ];
            [sourceImage setColor:adjusted atX:x+1 y:y+1];
            }
        }
    }
}

#pragma mark Palette matching
bool paletteExists(NSArray* newPalette, NSArray* existingPalettes)
{
    int matches = 0;
    for (NSArray* palette in existingPalettes) {
        for (NSColor *color in palette) {
            for(NSColor *newColor in newPalette)
            {
                if([color isEqualTo: newColor])
                    matches++;
            }
        }
    }
    
    return matches == 4;
}


#pragma mark Color matching
NSColor* MatchColor(NSColor* input, NSArray* palette)
{
    NSColor *output =  nil;
    float delta = 255*255 + 255*255 + 255*255;
    
    for (NSColor *color in palette) {
        
        float dist = GetDistanceBetweenColor( color, input);
        if (dist <= delta)
        {
            delta = dist;
            output = color;
        }
    }
   return output;
}

float GetDistanceBetweenColor(NSColor* a, NSColor* b)
{
    float d =   pow((b.redComponent *255.0 - a.redComponent *255.0), 2)*0.30
                + pow((b.greenComponent *255.0 - a.greenComponent *255.0), 2)*0.59
                + pow((b.blueComponent *255.0 - a.blueComponent *255.0), 2)*0.11;
    
    return d;
    
}

#pragma mark Image analysis

#pragma mark Palette import/export
NSData* convertPalettes(NSArray* palettes)
{
    NSMutableData *paletteData = [NSMutableData data];
    for (NSArray* palette in palettes) {
        for (NSColor *color in palette) {
            uint8_t colorAsByte = [[Palette sharedPalette] getByteFromColor:color ];
            [paletteData appendBytes: &colorAsByte  length:1];
        }
    }
    
	// Paletten skrives to gange: NES'ens palette-RAM er 32 bytes, hvor de sidste 16 er
	// sprite-paletter. At føje en NSMutableData til sig selv er ikke defineret, så der kopieres.
	[paletteData appendData: [paletteData copy]];
	return paletteData;
}

NSString* convertPalettesToJSON(NSArray* palettes)
{
    NSString *json = @"[\n" ;
    int c = 0;
    for (NSArray* palette in palettes) {
        json = [json stringByAppendingFormat: @"\t{\"palette%i\": [ ", c];
        for (NSColor *color in palette) {
            json = [json stringByAppendingFormat: @" \"%@\", ", [[Palette sharedPalette] getNameFromColor:color]];
        }
        json = [json substringToIndex: json.length-2];
        json = [json stringByAppendingString:@" ] },\n"];
        c++;
    }
    json = [json substringToIndex: json.length-2];
    json = [json stringByAppendingString: @"\n]"];
    
     return json;
}

NSArray* importPaletteFrom(NSString *file)
{
	NSData *paletteData = [NSData dataWithContentsOfFile:file];

	// Kastede før på både for korte og tomme filer, og igen når et opdigtet farvenavn
	// gav nil ind i array-literalen nedenfor.
	if(paletteData.length < 16)
	{
		printf("Error: '%s' is not a palette. A binary palette is 16 bytes.\n", file.UTF8String);
		return nil;
	}

	NSMutableArray *palettes = [[NSMutableArray alloc] init];
	for (int i = 0; i < 4; i++) {
		uint8_t hexPalette[4];
		[paletteData getBytes:hexPalette range:NSMakeRange(i*4, 4)];
		
		NSString* s0 = [NSString stringWithFormat:@"$%02hx", hexPalette[0]].uppercaseString;
		NSString* s1 = [NSString stringWithFormat:@"$%02hx", hexPalette[1]].uppercaseString;
		NSString* s2 = [NSString stringWithFormat:@"$%02hx", hexPalette[2]].uppercaseString;
		NSString* s3 = [NSString stringWithFormat:@"$%02hx", hexPalette[3]].uppercaseString;
		
		NSColor *c0 = [[Palette sharedPalette] getColorFromName:s0];
		NSColor *c1 = [[Palette sharedPalette] getColorFromName:s1];
		NSColor *c2 = [[Palette sharedPalette] getColorFromName:s2];
		NSColor *c3 = [[Palette sharedPalette] getColorFromName:s3];
		
		if(!c0 || !c1 || !c2 || !c3)
		{
			printf("Error: '%s' contains a value that is not a NES color.\n", file.UTF8String);
			return nil;
		}

		NSArray *palette = @[c0, c1, c2, c3];
/*
		NSArray *palette = @[
		 	[[Palette sharedPalette] getColorFromName: [NSString stringWithFormat:@"$%02hx", hexPalette[0]]],
			[[Palette sharedPalette] getColorFromName: [NSString stringWithFormat:@"$%02hx", hexPalette[1]]],
			[[Palette sharedPalette] getColorFromName: [NSString stringWithFormat:@"$%02hx", hexPalette[2]]],
			[[Palette sharedPalette] getColorFromName: [NSString stringWithFormat:@"$%02hx", hexPalette[3]]]
		];
	*/
		[palettes addObject:palette];
	}
	return palettes;
}

NSArray *uniqueColorsInPalettes(NSArray *palettes)
{
	NSMutableArray *colors = [[NSMutableArray alloc] init];
	for(NSArray *palette in palettes)
	{
		for(NSColor *color in palette)
		{
			if(![colors doesContain:color])
				[colors addObject:color];
		}
	}
	
	return colors;
}

