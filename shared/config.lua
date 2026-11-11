-- shared/config.lua
-- Global settings used by both client and server.

Config = {}

Config.Debug = true            
Config.CheckInterval = 1000    
Config.DefaultRegion = 'countryside'  



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
    },
    countryside = {
        label = 'Countryside',
        zones = {
            'BANHAMC', 'BHAMCA', 'CHU', 'GREATC', 'LACT', 'LDAM', 'NOOSE',
            'PALHIGH', 'PALMPOW', 'TATAMO', 'TONGVAH', 'TONGVAV', 'WINDF',
        },
    },
    desert = {
        label = 'Blaine County Desert',
        zones = {
            'ALAMO', 'ARMYB', 'CALAFB', 'DESRT', 'GALFISH', 'GRAPES', 'HARMO',
            'HUMLAB', 'JAIL', 'LAGO', 'RTRAK', 'SANCHIA', 'SANDY', 'SLAB',
            'ZANCUDO', 'ZQ_UAR',
        },
    },
    north = {
        label = 'Paleto & Mount Chiliad',
        zones = {
            'BRADP', 'BRADT', 'CANNY', 'CCREAK', 'CMSW', 'ELGORL', 'MTCHIL',
            'MTGORDO', 'MTJOSE', 'NCHU', 'PALCOV', 'PALETO', 'PALFOR', 'PROCOB',
        },
    },
    ocean = {
        label = 'Open Ocean',
        zones = { 'OCEANA' },
    },
}