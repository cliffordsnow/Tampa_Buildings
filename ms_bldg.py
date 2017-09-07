"""
Translation rules for Microsoft Buildings

Copyright 2017 Clifford Snow

"""

def filterTags(attrs):
    if not attrs: 
        return

    tags = {}
    tags['building'] = 'yes'
    if 'HEIGHT' in attrs and attrs['HEIGHT'] != '':
        tags['height'] = attrs['HEIGHT']

    return tags

