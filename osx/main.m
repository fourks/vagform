//
//  main.m
//  osx
//
//  Created by M Norrby on 1/7/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <MacRuby/MacRuby.h>

int main(int argc, char *argv[])
{
    return macruby_main("rb_main.rb", argc, argv);
}