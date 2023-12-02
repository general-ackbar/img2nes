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
    NSDictionary *mainPalette;
}

+(Palette *)sharedPalette
{
    static Palette *sharedInstance;
    
    @synchronized(self)
    {
        if (!sharedInstance)
        {
            sharedInstance = [[Palette alloc] init];
            [sharedInstance initPalette];
            [sharedInstance setDefaultPalette];
        }

        return sharedInstance;
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
    return mainPalette;
}

-(void)initPalette
{
    mainPalette = @{
        @"$00" : [NSColor colorWithRed: 124/255.0 green:124/255.0 blue:124/255.0 alpha:1.0],
        @"$01" : [NSColor colorWithRed: 0/255.0 green:0/255.0 blue:252/255.0 alpha:1.0],
        @"$02" :[NSColor colorWithRed: 0/255.0 green:0/255.0 blue:188/255.0 alpha:1.0],
        @"$03" :[NSColor colorWithRed: 68/255.0 green:40/255.0 blue:188/255.0 alpha:1.0],
        @"$04" :[NSColor colorWithRed: 148/255.0 green:0/255.0 blue:132/255.0 alpha:1.0],
        @"$05" :[NSColor colorWithRed: 168/255.0 green:0/255.0 blue:32/255.0 alpha:1.0],
        @"$06" :[NSColor colorWithRed: 168/255.0 green:16/255.0 blue:0/255.0 alpha:1.0],
        @"$07" :[NSColor colorWithRed: 136/255.0 green:20/255.0 blue:0/255.0 alpha:1.0],
        @"$08" :[NSColor colorWithRed: 80/255.0 green:48/255.0 blue:0/255.0 alpha:1.0],
        @"$09" :[NSColor colorWithRed: 0/255.0 green:120/255.0 blue:0/255.0 alpha:1.0],
        @"$0A" :[NSColor colorWithRed: 0/255.0 green:104/255.0 blue:0/255.0 alpha:1.0],
        @"$0B" :[NSColor colorWithRed: 0/255.0 green:88/255.0 blue:0/255.0 alpha:1.0],
        @"$0C" :[NSColor colorWithRed: 0/255.0 green:64/255.0 blue:88/255.0 alpha:1.0],
        @"$0D" :[NSColor colorWithRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$0E" :[NSColor colorWithRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$0F" :[NSColor colorWithRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$10" :[NSColor colorWithRed: 188/255.0 green:188/255.0 blue:188/255.0 alpha:1.0],
        @"$11" :[NSColor colorWithRed: 0/255.0 green:120/255.0 blue:248/255.0 alpha:1.0],
        @"$12" :[NSColor colorWithRed: 0/255.0 green:88/255.0 blue:248/255.0 alpha:1.0],
        @"$13" :[NSColor colorWithRed: 104/255.0 green:68/255.0 blue:252/255.0 alpha:1.0],
        @"$14" :[NSColor colorWithRed: 216/255.0 green:0/255.0 blue:204/255.0 alpha:1.0],
        @"$15" :[NSColor colorWithRed: 228/255.0 green:0/255.0 blue:88/255.0 alpha:1.0],
        @"$16" :[NSColor colorWithRed: 248/255.0 green:56/255.0 blue:0/255.0 alpha:1.0],
        @"$17" :[NSColor colorWithRed: 228/255.0 green:92/255.0 blue:16/255.0 alpha:1.0],
        @"$18" :[NSColor colorWithRed: 172/255.0 green:124/255.0 blue:0/255.0 alpha:1.0],
        @"$19" :[NSColor colorWithRed: 0/255.0 green:184/255.0 blue:0/255.0 alpha:1.0],
        @"$1A" :[NSColor colorWithRed: 0/255.0 green:168/255.0 blue:0/255.0 alpha:1.0],
        @"$1B" :[NSColor colorWithRed: 0/255.0 green:168/255.0 blue:68/255.0 alpha:1.0],
        @"$1C" :[NSColor colorWithRed: 0/255.0 green:136/255.0 blue:136/255.0 alpha:1.0],
        @"$1D" :[NSColor colorWithRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$1E" :[NSColor colorWithRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$1F" :[NSColor colorWithRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$20" :[NSColor colorWithRed: 248/255.0 green:248/255.0 blue:248/255.0 alpha:1.0],
        @"$21" :[NSColor colorWithRed: 60/255.0 green:188/255.0 blue:252/255.0 alpha:1.0],
        @"$22" :[NSColor colorWithRed: 104/255.0 green:136/255.0 blue:252/255.0 alpha:1.0],
        @"$23" :[NSColor colorWithRed: 152/255.0 green:120/255.0 blue:248/255.0 alpha:1.0],
        @"$24" :[NSColor colorWithRed: 248/255.0 green:120/255.0 blue:248/255.0 alpha:1.0],
        @"$25" :[NSColor colorWithRed: 248/255.0 green:88/255.0 blue:152/255.0 alpha:1.0],
        @"$26" :[NSColor colorWithRed: 248/255.0 green:120/255.0 blue:88/255.0 alpha:1.0],
        @"$27" :[NSColor colorWithRed: 252/255.0 green:160/255.0 blue:68/255.0 alpha:1.0],
        @"$28" :[NSColor colorWithRed: 248/255.0 green:184/255.0 blue:0/255.0 alpha:1.0],
        @"$29" :[NSColor colorWithRed: 184/255.0 green:248/255.0 blue:24/255.0 alpha:1.0],
        @"$2A" :[NSColor colorWithRed: 88/255.0 green:216/255.0 blue:84/255.0 alpha:1.0],
        @"$2B" :[NSColor colorWithRed: 88/255.0 green:248/255.0 blue:152/255.0 alpha:1.0],
        @"$2C" :[NSColor colorWithRed: 0/255.0 green:232/255.0 blue:216/255.0 alpha:1.0],
        @"$2D" :[NSColor colorWithRed: 120/255.0 green:120/255.0 blue:120/255.0 alpha:1.0],
        @"$2E" :[NSColor colorWithRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$2F" :[NSColor colorWithRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$30" :[NSColor colorWithRed: 252/255.0 green:252/255.0 blue:252/255.0 alpha:1.0],
        @"$31" :[NSColor colorWithRed: 164/255.0 green:228/255.0 blue:252/255.0 alpha:1.0],
        @"$32" :[NSColor colorWithRed: 184/255.0 green:184/255.0 blue:248/255.0 alpha:1.0],
        @"$33" :[NSColor colorWithRed: 216/255.0 green:184/255.0 blue:248/255.0 alpha:1.0],
        @"$34" :[NSColor colorWithRed: 248/255.0 green:184/255.0 blue:248/255.0 alpha:1.0],
        @"$35" :[NSColor colorWithRed: 248/255.0 green:164/255.0 blue:192/255.0 alpha:1.0],
        @"$36" :[NSColor colorWithRed: 240/255.0 green:208/255.0 blue:176/255.0 alpha:1.0],
        @"$37" :[NSColor colorWithRed: 252/255.0 green:224/255.0 blue:168/255.0 alpha:1.0],
        @"$38" :[NSColor colorWithRed: 248/255.0 green:216/255.0 blue:120/255.0 alpha:1.0],
        @"$39" :[NSColor colorWithRed: 216/255.0 green:248/255.0 blue:120/255.0 alpha:1.0],
        @"$3A" :[NSColor colorWithRed: 184/255.0 green:248/255.0 blue:184/255.0 alpha:1.0],
        @"$3B" :[NSColor colorWithRed: 184/255.0 green:248/255.0 blue:216/255.0 alpha:1.0],
        @"$3C" :[NSColor colorWithRed: 0/255.0 green:252/255.0 blue:252/255.0 alpha:1.0],
        @"$3D" :[NSColor colorWithRed: 248/255.0 green:216/255.0 blue:248/255.0 alpha:1.0],
        @"$3E" :[NSColor colorWithRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
        @"$3F" :[NSColor colorWithRed: 0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0],
    };
    
    
}

@end
