-- Global settings used by both client and server.

Config = {}

Config.Debug = true            
Config.CheckInterval = 1000    
Config.WeatherTransitionTime = 15.0  -- seconds to blend from one weather to the next
Config.EnforceInterval = 1000        -- ms between re-applying weather/time so GTA doesn't drift
Config.DefaultRegion = 'countryside'  

-- Fallbacks used if a region doesn't set its own defaults
Config.DefaultWeather = 'CLEAR'
Config.DefaultHour = 12

-- Weather types the system accepts (id = GTA's internal name, label = shown in the UI later)
Config.WeatherTypes = {
    { id = 'EXTRASUNNY', label = 'Extra Sunny' },
    { id = 'CLEAR',      label = 'Clear' },
    { id = 'CLOUDS',     label = 'Cloudy' },
    { id = 'OVERCAST',   label = 'Overcast' },
    { id = 'SMOG',       label = 'Smog' },
    { id = 'FOGGY',      label = 'Foggy' },
    { id = 'CLEARING',   label = 'Clearing' },
    { id = 'RAIN',       label = 'Rain' },
    { id = 'THUNDER',    label = 'Thunderstorm' },
    { id = 'SNOWLIGHT',  label = 'Light Snow' },
    { id = 'SNOW',       label = 'Snow' },
    { id = 'BLIZZARD',   label = 'Blizzard' },
    { id = 'XMAS',       label = 'Snow (Christmas)' },
}




Config.Regions = {
    city = {
        label = 'Los Santos',
        zones = {
            'AIRP', 'ALTA', 'BANNING', 'BEACH', 'BURTON', 'CHAMH', 'CHIL', 'CYPRE',
            'DAVIS', 'DELBE', 'DELPE', 'DELSOL', 'DOWNT', 'DTVINE', 'EAST_V', 'EBURO',
            'ELYSIAN', 'GOLF', 'HAWICK', 'HORS', 'KOREAT', 'LEGSQU', 'LMESA', 'LOSPUER',
            'MIRR', 'MORN', 'MOVIE', 'MURRI', 'PBLUFF', 'PBOX', 'RANCHO', 'RGLEN',
            'RICHM', 'ROCKF', 'SKID', 'STAD', 'STRAW', 'TERMINA', 'TEXTI', 'VCANA',
            'VESP', 'VINE', 'WVINE', 'ZP_ORT',
        },
        defaultWeather = 'CLEAR',
        defaultHour = 12,
    },
    countryside = {
        label = 'Countryside',
        zones = {
            'BANHAMC', 'BHAMCA', 'CHU', 'GREATC', 'LACT', 'LDAM', 'NOOSE',
            'PALHIGH', 'PALMPOW', 'TATAMO', 'TONGVAH', 'TONGVAV', 'WINDF',
        },
        defaultWeather = 'CLOUDS',
        defaultHour = 10,
    },
    desert = {
        label = 'Blaine County Desert',
        zones = {
            'ALAMO', 'ARMYB', 'CALAFB', 'DESRT', 'GALFISH', 'GRAPES', 'HARMO',
            'HUMLAB', 'JAIL', 'LAGO', 'RTRAK', 'SANCHIA', 'SANDY', 'SLAB',
            'ZANCUDO', 'ZQ_UAR',
        },
        defaultWeather = 'EXTRASUNNY',
        defaultHour = 14,
    },
    north = {
        label = 'Paleto & Mount Chiliad',
        zones = {
            'BRADP', 'BRADT', 'CANNY', 'CCREAK', 'CMSW', 'ELGORL', 'MTCHIL',
            'MTGORDO', 'MTJOSE', 'NCHU', 'PALCOV', 'PALETO', 'PALFOR', 'PROCOB',
        },
        defaultWeather = 'OVERCAST',
        defaultHour = 8,
    },
    ocean = {
        label = 'Open Ocean',
        zones = { 'OCEANA' },
        defaultWeather = 'CLEARING',
        defaultHour = 17,
    },
}