r←MS3_init

⎕se.SALT.Load'APLProcess'
⎕se.SALT.Load ##.TESTSOURCE,'../../Selenium'

myapl←⎕NEW #.APLProcess((##.TESTSOURCE,'../DUI')(''))