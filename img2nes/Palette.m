//
//  palette.m
//  CHREditor
//
//  Created by Jonatan Yde on 13/11/2023.
//

#import "Palette.h"

@implementation Palette
{
    NSColor* palette[4];
    NSDictionary *systemPalette;
}

+(Palette *)sharedPalette
{
    static Palette *sharedInstance;
    
    @synchronized(self)
    {
        if (!sharedInstance)
        {
            sharedInstance = [[Palette alloc] init];
            [sharedInstance initPaletteMesen];
            [sharedInstance setDefaultPalette];
        }

        return sharedInstance;
    }
}

-(void)shiftSystemPalette:(int)number
{
    switch (number) {
        case 0:
            [self initPaletteMesen];
            break;
        case 1:
            [self initPaletteFCEUX];
            break;
        case 2:
            [self initPalette];
            break;

        default:
            break;
    }
}

-(void)setColorFrom:(NSString *) indexName at:(NSInteger)index
{
    palette[index] = [self getColorFromName:indexName];
}
-(void)setColor:(NSColor *) color at:(NSInteger)index
{
//    if([[self NESpalette] allKeysForObject:color].count > 0)
        palette[index] = color;
    
}

-(NSColor*)colorAt:(NSInteger)index
{
    return palette[index];
}

-(int)indexOf:(NSColor*)color
{
    for(int i = 0; i < 4; i++)
    {
        if(palette[i] == color)
            return i;
    }
    
    return -1;
}

-(NSArray*)getPalette
{
    return @[palette[0], palette[1], palette[2], palette[3]];
}

-(NSArray*)getIndexedPalette
{
    return @[[self getNameFromColor:palette[0]], [self getNameFromColor:palette[1]], [self getNameFromColor:palette[2]], [self getNameFromColor:palette[3]]];
}
-(NSColor*)getColorFromName:(NSString*)name
{
    return [[self NESpalette] objectForKey:name];
}

-(NSString*)getNameFromColor:(NSColor*)color
{
    return [[[self NESpalette] allKeysForObject:color] firstObject];
}

-(void)setPalette:(NSArray*)newPalette
{
    for(int i = 0; i < (newPalette.count < 4 ? newPalette.count :  4); i++)
    {
        NSColor *color = [newPalette objectAtIndex:i];
//        if([mainPalette doesContain:color])
            palette[i] = color;
        
    }
}




-(uint8_t)getByteFromColor:(NSColor*)color
{
    NSString* name = [[[self NESpalette] allKeysForObject:color] firstObject];
    name = [name substringFromIndex:1]; //remove "$"
    
    
    const char *chars = [name UTF8String];

    unsigned long wholeByte = strtoul(chars, NULL, 16);
    
    return (uint8_t)wholeByte;
}

-(uint8_t)getByteFromName:(NSString*)color
{
    NSString* name = [color substringFromIndex:1]; //remove "$"
    
    
    const char *chars = [name UTF8String];

    unsigned long wholeByte = strtoul(chars, NULL, 16);
    
    return (uint8_t)wholeByte;
}

-(NSString*)getNameFromIndex:(NSInteger)index
{
    return [self getNameFromColor: [[[self NESpalette] allValues] objectAtIndex: index]];
}

-(void)setDefaultPalette
{
    palette[0] = [self getColorFromName: @"$24"];
    palette[1] = [self getColorFromName: @"$27"];
    palette[2] = [self getColorFromName: @"$10"];
    palette[3] = [self getColorFromName: @"$0E"];
    
}

-(NSDictionary*)NESpalette
{
    return systemPalette;
}

-(void)initPaletteMesen
{
    systemPalette = @{
        @"$00" : [NSColor colorWithCalibratedRed: 102./255.0 green:102./255.0 blue:102./255.0 alpha:1.0],
        @"$01" : [NSColor colorWithCalibratedRed: 0./255.0 green:42./255.0 blue:136./255.0 alpha:1.0],
        @"$02" : [NSColor colorWithCalibratedRed: 20./255.0 green:18./255.0 blue:167./255.0 alpha:1.0],
        @"$03" : [NSColor colorWithCalibratedRed: 59./255.0 green:0./255.0 blue:164./255.0 alpha:1.0],
        @"$04" : [NSColor colorWithCalibratedRed: 92./255.0 green:0./255.0 blue:126./255.0 alpha:1.0],
        @"$05" : [NSColor colorWithCalibratedRed: 110./255.0 green:0./255.0 blue:64./255.0 alpha:1.0],
        @"$06" : [NSColor colorWithCalibratedRed: 108./255.0 green:6./255.0 blue:0./255.0 alpha:1.0],
        @"$07" : [NSColor colorWithCalibratedRed: 86./255.0 green:29./255.0 blue:0./255.0 alpha:1.0],
        @"$08" : [NSColor colorWithCalibratedRed: 51./255.0 green:53./255.0 blue:0./255.0 alpha:1.0],
        @"$09" : [NSColor colorWithCalibratedRed: 11./255.0 green:72./255.0 blue:0./255.0 alpha:1.0],
        @"$0A" : [NSColor colorWithCalibratedRed: 0./255.0 green:82./255.0 blue:0./255.0 alpha:1.0],
        @"$0B" : [NSColor colorWithCalibratedRed: 0./255.0 green:79./255.0 blue:8./255.0 alpha:1.0],
        @"$0C" : [NSColor colorWithCalibratedRed: 0./255.0 green:64./255.0 blue:77./255.0 alpha:1.0],
        @"$0D" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$0E" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$0F" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        
        @"$10" : [NSColor colorWithCalibratedRed: 173./255.0 green:173./255.0 blue:173./255.0 alpha:1.0],
        @"$11" : [NSColor colorWithCalibratedRed: 21./255.0 green:95./255.0 blue:217./255.0 alpha:1.0],
        @"$12" : [NSColor colorWithCalibratedRed: 66./255.0 green:64./255.0 blue:255./255.0 alpha:1.0],
        @"$13" : [NSColor colorWithCalibratedRed: 117./255.0 green:39./255.0 blue:254./255.0 alpha:1.0],
        @"$14" : [NSColor colorWithCalibratedRed: 160./255.0 green:26./255.0 blue:204./255.0 alpha:1.0],
        @"$15" : [NSColor colorWithCalibratedRed: 183./255.0 green:30./255.0 blue:123./255.0 alpha:1.0],
        @"$16" : [NSColor colorWithCalibratedRed: 181./255.0 green:49./255.0 blue:32./255.0 alpha:1.0],
        @"$17" : [NSColor colorWithCalibratedRed: 153./255.0 green:78./255.0 blue:0./255.0 alpha:1.0],
        @"$18" : [NSColor colorWithCalibratedRed: 107./255.0 green:109./255.0 blue:0./255.0 alpha:1.0],
        @"$19" : [NSColor colorWithCalibratedRed: 56./255.0 green:135./255.0 blue:0./255.0 alpha:1.0],
        @"$1A" : [NSColor colorWithCalibratedRed: 12./255.0 green:147./255.0 blue:0./255.0 alpha:1.0],
        @"$1B" : [NSColor colorWithCalibratedRed: 0./255.0 green:143./255.0 blue:50./255.0 alpha:1.0],
        @"$1C" : [NSColor colorWithCalibratedRed: 0./255.0 green:124./255.0 blue:141./255.0 alpha:1.0],
        @"$1D" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$1E" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$1F" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        
        @"$20" : [NSColor colorWithCalibratedRed: 255./255.0 green:254./255.0 blue:255./255.0 alpha:1.0],
        @"$21" : [NSColor colorWithCalibratedRed: 100./255.0 green:176./255.0 blue:255./255.0 alpha:1.0],
        @"$22" : [NSColor colorWithCalibratedRed: 146./255.0 green:144./255.0 blue:255./255.0 alpha:1.0],
        @"$23" : [NSColor colorWithCalibratedRed: 198./255.0 green:118./255.0 blue:255./255.0 alpha:1.0],
        @"$24" : [NSColor colorWithCalibratedRed: 243./255.0 green:106./255.0 blue:255./255.0 alpha:1.0],
        @"$25" : [NSColor colorWithCalibratedRed: 254./255.0 green:110./255.0 blue:204./255.0 alpha:1.0],
        @"$26" : [NSColor colorWithCalibratedRed: 254./255.0 green:129./255.0 blue:112./255.0 alpha:1.0],
        @"$27" : [NSColor colorWithCalibratedRed: 234./255.0 green:158./255.0 blue:34./255.0 alpha:1.0],
        @"$28" : [NSColor colorWithCalibratedRed: 188./255.0 green:190./255.0 blue:0./255.0 alpha:1.0],
        @"$29" : [NSColor colorWithCalibratedRed: 136./255.0 green:216./255.0 blue:0./255.0 alpha:1.0],
        @"$2A" : [NSColor colorWithCalibratedRed: 92./255.0 green:228./255.0 blue:48./255.0 alpha:1.0],
        @"$2B" : [NSColor colorWithCalibratedRed: 69./255.0 green:224./255.0 blue:130./255.0 alpha:1.0],
        @"$2C" : [NSColor colorWithCalibratedRed: 72./255.0 green:205./255.0 blue:222./255.0 alpha:1.0],
        @"$2D" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$2E" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$2F" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        
        @"$30" : [NSColor colorWithCalibratedRed: 255./255.0 green:254./255.0 blue:252./255.0 alpha:1.0],
        @"$31" : [NSColor colorWithCalibratedRed: 192./255.0 green:223./255.0 blue:255./255.0 alpha:1.0],
        @"$32" : [NSColor colorWithCalibratedRed: 211./255.0 green:210./255.0 blue:255./255.0 alpha:1.0],
        @"$33" : [NSColor colorWithCalibratedRed: 232./255.0 green:200./255.0 blue:255./255.0 alpha:1.0],
        @"$34" : [NSColor colorWithCalibratedRed: 251./255.0 green:194./255.0 blue:255./255.0 alpha:1.0],
        @"$35" : [NSColor colorWithCalibratedRed: 254./255.0 green:196./255.0 blue:234./255.0 alpha:1.0],
        @"$36" : [NSColor colorWithCalibratedRed: 254./255.0 green:204./255.0 blue:197./255.0 alpha:1.0],
        @"$37" : [NSColor colorWithCalibratedRed: 247./255.0 green:216./255.0 blue:165./255.0 alpha:1.0],
        @"$38" : [NSColor colorWithCalibratedRed: 228./255.0 green:229./255.0 blue:148./255.0 alpha:1.0],
        @"$39" : [NSColor colorWithCalibratedRed: 207./255.0 green:239./255.0 blue:150./255.0 alpha:1.0],
        @"$3A" : [NSColor colorWithCalibratedRed: 189./255.0 green:244./255.0 blue:171./255.0 alpha:1.0],
        @"$3B" : [NSColor colorWithCalibratedRed: 179./255.0 green:243./255.0 blue:204./255.0 alpha:1.0],
        @"$3C" : [NSColor colorWithCalibratedRed: 181./255.0 green:235./255.0 blue:242./255.0 alpha:1.0],
        @"$3D" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$3E" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$3F" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0]

    };
}

-(void)initPaletteFCEUX
{
    systemPalette = @{
        @"$00" : [NSColor colorWithCalibratedRed: 116./255.0 green:116./255.0 blue:116./255.0 alpha:1.0],
        @"$01" : [NSColor colorWithCalibratedRed: 36./255.0 green:24./255.0 blue:140./255.0 alpha:1.0],
        @"$02" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:168./255.0 alpha:1.0],
        @"$03" : [NSColor colorWithCalibratedRed: 68./255.0 green:0./255.0 blue:156./255.0 alpha:1.0],
        @"$04" : [NSColor colorWithCalibratedRed: 140./255.0 green:0./255.0 blue:116./255.0 alpha:1.0],
        @"$05" : [NSColor colorWithCalibratedRed: 168./255.0 green:0./255.0 blue:16./255.0 alpha:1.0],
        @"$06" : [NSColor colorWithCalibratedRed: 164./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$07" : [NSColor colorWithCalibratedRed: 124./255.0 green:8./255.0 blue:0./255.0 alpha:1.0],
        @"$08" : [NSColor colorWithCalibratedRed: 64./255.0 green:44./255.0 blue:0./255.0 alpha:1.0],
        @"$09" : [NSColor colorWithCalibratedRed: 0./255.0 green:68./255.0 blue:0./255.0 alpha:1.0],
        @"$0A" : [NSColor colorWithCalibratedRed: 0./255.0 green:80./255.0 blue:0./255.0 alpha:1.0],
        @"$0B" : [NSColor colorWithCalibratedRed: 0./255.0 green:60./255.0 blue:20./255.0 alpha:1.0],
        @"$0C" : [NSColor colorWithCalibratedRed: 24./255.0 green:60./255.0 blue:92./255.0 alpha:1.0],
        @"$0D" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$0E" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$0F" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],

        @"$10" : [NSColor colorWithCalibratedRed: 188./255.0 green:188./255.0 blue:188./255.0 alpha:1.0],
        @"$11" : [NSColor colorWithCalibratedRed: 0./255.0 green:112./255.0 blue:236./255.0 alpha:1.0],
        @"$12" : [NSColor colorWithCalibratedRed: 32./255.0 green:56./255.0 blue:236./255.0 alpha:1.0],
        @"$13" : [NSColor colorWithCalibratedRed: 128./255.0 green:0./255.0 blue:240./255.0 alpha:1.0],
        @"$14" : [NSColor colorWithCalibratedRed: 188./255.0 green:0./255.0 blue:188./255.0 alpha:1.0],
        @"$15" : [NSColor colorWithCalibratedRed: 228./255.0 green:0./255.0 blue:88./255.0 alpha:1.0],
        @"$16" : [NSColor colorWithCalibratedRed: 216./255.0 green:40./255.0 blue:0./255.0 alpha:1.0],
        @"$17" : [NSColor colorWithCalibratedRed: 200./255.0 green:76./255.0 blue:12./255.0 alpha:1.0],
        @"$18" : [NSColor colorWithCalibratedRed: 136./255.0 green:112./255.0 blue:0./255.0 alpha:1.0],
        @"$19" : [NSColor colorWithCalibratedRed: 0./255.0 green:148./255.0 blue:0./255.0 alpha:1.0],
        @"$1A" : [NSColor colorWithCalibratedRed: 0./255.0 green:168./255.0 blue:0./255.0 alpha:1.0],
        @"$1B" : [NSColor colorWithCalibratedRed: 0./255.0 green:144./255.0 blue:56./255.0 alpha:1.0],
        @"$1C" : [NSColor colorWithCalibratedRed: 0./255.0 green:128./255.0 blue:136./255.0 alpha:1.0],
        @"$1D" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$1E" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$1F" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],

        @"$20" : [NSColor colorWithCalibratedRed: 252./255.0 green:252./255.0 blue:252./255.0 alpha:1.0],
        @"$21" : [NSColor colorWithCalibratedRed: 60./255.0 green:188./255.0 blue:252./255.0 alpha:1.0],
        @"$22" : [NSColor colorWithCalibratedRed: 92./255.0 green:148./255.0 blue:252./255.0 alpha:1.0],
        @"$23" : [NSColor colorWithCalibratedRed: 204./255.0 green:136./255.0 blue:252./255.0 alpha:1.0],
        @"$24" : [NSColor colorWithCalibratedRed: 244./255.0 green:120./255.0 blue:252./255.0 alpha:1.0],
        @"$25" : [NSColor colorWithCalibratedRed: 252./255.0 green:116./255.0 blue:180./255.0 alpha:1.0],
        @"$26" : [NSColor colorWithCalibratedRed: 252./255.0 green:116./255.0 blue:96./255.0 alpha:1.0],
        @"$27" : [NSColor colorWithCalibratedRed: 252./255.0 green:152./255.0 blue:56./255.0 alpha:1.0],
        @"$28" : [NSColor colorWithCalibratedRed: 240./255.0 green:188./255.0 blue:60./255.0 alpha:1.0],
        @"$29" : [NSColor colorWithCalibratedRed: 128./255.0 green:208./255.0 blue:16./255.0 alpha:1.0],
        @"$2A" : [NSColor colorWithCalibratedRed: 76./255.0 green:220./255.0 blue:72./255.0 alpha:1.0],
        @"$2B" : [NSColor colorWithCalibratedRed: 88./255.0 green:248./255.0 blue:152./255.0 alpha:1.0],
        @"$2C" : [NSColor colorWithCalibratedRed: 0./255.0 green:232./255.0 blue:216./255.0 alpha:1.0],
        @"$2D" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$2E" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$2F" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        
        @"$30" : [NSColor colorWithCalibratedRed: 252./255.0 green:252./255.0 blue:252./255.0 alpha:1.0],
        @"$31" : [NSColor colorWithCalibratedRed: 168./255.0 green:228./255.0 blue:252./255.0 alpha:1.0],
        @"$32" : [NSColor colorWithCalibratedRed: 196./255.0 green:212./255.0 blue:252./255.0 alpha:1.0],
        @"$33" : [NSColor colorWithCalibratedRed: 212./255.0 green:200./255.0 blue:252./255.0 alpha:1.0],
        @"$34" : [NSColor colorWithCalibratedRed: 252./255.0 green:196./255.0 blue:252./255.0 alpha:1.0],
        @"$35" : [NSColor colorWithCalibratedRed: 252./255.0 green:196./255.0 blue:216./255.0 alpha:1.0],
        @"$36" : [NSColor colorWithCalibratedRed: 252./255.0 green:188./255.0 blue:176./255.0 alpha:1.0],
        @"$37" : [NSColor colorWithCalibratedRed: 252./255.0 green:216./255.0 blue:168./255.0 alpha:1.0],
        @"$38" : [NSColor colorWithCalibratedRed: 252./255.0 green:228./255.0 blue:160./255.0 alpha:1.0],
        @"$39" : [NSColor colorWithCalibratedRed: 224./255.0 green:252./255.0 blue:160./255.0 alpha:1.0],
        @"$3A" : [NSColor colorWithCalibratedRed: 168./255.0 green:240./255.0 blue:188./255.0 alpha:1.0],
        @"$3B" : [NSColor colorWithCalibratedRed: 176./255.0 green:252./255.0 blue:204./255.0 alpha:1.0],
        @"$3C" : [NSColor colorWithCalibratedRed: 156./255.0 green:252./255.0 blue:240./255.0 alpha:1.0],
        @"$3D" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$3E" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0],
        @"$3F" : [NSColor colorWithCalibratedRed: 0./255.0 green:0./255.0 blue:0./255.0 alpha:1.0]

    };
}

-(void)initPalette
{
    systemPalette = @{
        @"$00" : [NSColor colorWithCalibratedRed: 124/255.0 green:124/255.0 blue:124/255.0 alpha:1.0],
        @"$01" : [NSColor colorWithCalibratedRed: 0/255.0 green:0/255.0 blue:252/255.0 alpha:1.0],
        @"$02" :[NSColor colorWithCalibratedRed: 0/255.0 green:0/255.0 blue:188/255.0 alpha:1.0],
        @"$03" :[NSColor colorWithCalibratedRed: 68/255.0 green:40/255.0 blue:188/255.0 alpha:1.0],
        @"$04" :[NSColor colorWithCalibratedRed: 148/255.0 green:0/255.0 blue:132/255.0 alpha:1.0],
        @"$05" :[NSColor colorWithCalibratedRed: 168/255.0 green:0/255.0 blue:32/255.0 alpha:1.0],
        @"$06" :[NSColor colorWithCalibratedRed: 168/255.0 green:16/255.0 blue:0/255.0 alpha:1.0],
        @"$07" :[NSColor colorWithCalibratedRed: 136/255.0 green:20/255.0 blue:0/255.0 alpha:1.0],
        @"$08" :[NSColor colorWithCalibratedRed: 80/255.0 green:48/255.0 blue:0/255.0 alpha:1.0],
        @"$09" :[NSColor colorWithCalibratedRed: 0/255.0 green:120/255.0 blue:0/255.0 alpha:1.0],
        @"$0A" :[NSColor colorWithCalibratedRed: 0/255.0 green:104/255.0 blue:0/255.0 alpha:1.0],
        @"$0B" :[NSColor colorWithCalibratedRed: 0/255.0 green:88/255.0 blue:0/255.0 alpha:1.0],
        @"$0C" :[NSColor colorWithCalibratedRed: 0/255.0 green:64/255.0 blue:88/255.0 alpha:1.0],
        @"$0D" :[NSColor colorWithCalibratedRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$0E" :[NSColor colorWithCalibratedRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$0F" :[NSColor colorWithCalibratedRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$10" :[NSColor colorWithCalibratedRed: 188/255.0 green:188/255.0 blue:188/255.0 alpha:1.0],
        @"$11" :[NSColor colorWithCalibratedRed: 0/255.0 green:120/255.0 blue:248/255.0 alpha:1.0],
        @"$12" :[NSColor colorWithCalibratedRed: 0/255.0 green:88/255.0 blue:248/255.0 alpha:1.0],
        @"$13" :[NSColor colorWithCalibratedRed: 104/255.0 green:68/255.0 blue:252/255.0 alpha:1.0],
        @"$14" :[NSColor colorWithCalibratedRed: 216/255.0 green:0/255.0 blue:204/255.0 alpha:1.0],
        @"$15" :[NSColor colorWithCalibratedRed: 228/255.0 green:0/255.0 blue:88/255.0 alpha:1.0],
        @"$16" :[NSColor colorWithCalibratedRed: 248/255.0 green:56/255.0 blue:0/255.0 alpha:1.0],
        @"$17" :[NSColor colorWithCalibratedRed: 228/255.0 green:92/255.0 blue:16/255.0 alpha:1.0],
        @"$18" :[NSColor colorWithCalibratedRed: 172/255.0 green:124/255.0 blue:0/255.0 alpha:1.0],
        @"$19" :[NSColor colorWithCalibratedRed: 0/255.0 green:184/255.0 blue:0/255.0 alpha:1.0],
        @"$1A" :[NSColor colorWithCalibratedRed: 0/255.0 green:168/255.0 blue:0/255.0 alpha:1.0],
        @"$1B" :[NSColor colorWithCalibratedRed: 0/255.0 green:168/255.0 blue:68/255.0 alpha:1.0],
        @"$1C" :[NSColor colorWithCalibratedRed: 0/255.0 green:136/255.0 blue:136/255.0 alpha:1.0],
        @"$1D" :[NSColor colorWithCalibratedRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$1E" :[NSColor colorWithCalibratedRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$1F" :[NSColor colorWithCalibratedRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$20" :[NSColor colorWithCalibratedRed: 248/255.0 green:248/255.0 blue:248/255.0 alpha:1.0],
        @"$21" :[NSColor colorWithCalibratedRed: 60/255.0 green:188/255.0 blue:252/255.0 alpha:1.0],
        @"$22" :[NSColor colorWithCalibratedRed: 104/255.0 green:136/255.0 blue:252/255.0 alpha:1.0],
        @"$23" :[NSColor colorWithCalibratedRed: 152/255.0 green:120/255.0 blue:248/255.0 alpha:1.0],
        @"$24" :[NSColor colorWithCalibratedRed: 248/255.0 green:120/255.0 blue:248/255.0 alpha:1.0],
        @"$25" :[NSColor colorWithCalibratedRed: 248/255.0 green:88/255.0 blue:152/255.0 alpha:1.0],
        @"$26" :[NSColor colorWithCalibratedRed: 248/255.0 green:120/255.0 blue:88/255.0 alpha:1.0],
        @"$27" :[NSColor colorWithCalibratedRed: 252/255.0 green:160/255.0 blue:68/255.0 alpha:1.0],
        @"$28" :[NSColor colorWithCalibratedRed: 248/255.0 green:184/255.0 blue:0/255.0 alpha:1.0],
        @"$29" :[NSColor colorWithCalibratedRed: 184/255.0 green:248/255.0 blue:24/255.0 alpha:1.0],
        @"$2A" :[NSColor colorWithCalibratedRed: 88/255.0 green:216/255.0 blue:84/255.0 alpha:1.0],
        @"$2B" :[NSColor colorWithCalibratedRed: 88/255.0 green:248/255.0 blue:152/255.0 alpha:1.0],
        @"$2C" :[NSColor colorWithCalibratedRed: 0/255.0 green:232/255.0 blue:216/255.0 alpha:1.0],
        @"$2D" :[NSColor colorWithCalibratedRed: 120/255.0 green:120/255.0 blue:120/255.0 alpha:1.0],
        @"$2E" :[NSColor colorWithCalibratedRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$2F" :[NSColor colorWithCalibratedRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$30" :[NSColor colorWithCalibratedRed: 252/255.0 green:252/255.0 blue:252/255.0 alpha:1.0],
        @"$31" :[NSColor colorWithCalibratedRed: 164/255.0 green:228/255.0 blue:252/255.0 alpha:1.0],
        @"$32" :[NSColor colorWithCalibratedRed: 184/255.0 green:184/255.0 blue:248/255.0 alpha:1.0],
        @"$33" :[NSColor colorWithCalibratedRed: 216/255.0 green:184/255.0 blue:248/255.0 alpha:1.0],
        @"$34" :[NSColor colorWithCalibratedRed: 248/255.0 green:184/255.0 blue:248/255.0 alpha:1.0],
        @"$35" :[NSColor colorWithCalibratedRed: 248/255.0 green:164/255.0 blue:192/255.0 alpha:1.0],
        @"$36" :[NSColor colorWithCalibratedRed: 240/255.0 green:208/255.0 blue:176/255.0 alpha:1.0],
        @"$37" :[NSColor colorWithCalibratedRed: 252/255.0 green:224/255.0 blue:168/255.0 alpha:1.0],
        @"$38" :[NSColor colorWithCalibratedRed: 248/255.0 green:216/255.0 blue:120/255.0 alpha:1.0],
        @"$39" :[NSColor colorWithCalibratedRed: 216/255.0 green:248/255.0 blue:120/255.0 alpha:1.0],
        @"$3A" :[NSColor colorWithCalibratedRed: 184/255.0 green:248/255.0 blue:184/255.0 alpha:1.0],
        @"$3B" :[NSColor colorWithCalibratedRed: 184/255.0 green:248/255.0 blue:216/255.0 alpha:1.0],
        @"$3C" :[NSColor colorWithCalibratedRed: 0/255.0 green:252/255.0 blue:252/255.0 alpha:1.0],
        @"$3D" :[NSColor colorWithCalibratedRed: 248/255.0 green:216/255.0 blue:248/255.0 alpha:1.0],
        @"$3E" :[NSColor colorWithCalibratedRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$3F" :[NSColor colorWithCalibratedRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
    };
    
    
}

@end
