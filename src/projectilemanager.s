;---------- Includes ----------
              INCDIR      "include"
              INCLUDE     "hw.i"
;---------- Constants ---------
;----------- Variables --------
;---------- Subroutines -------
    SECTION CODE

ProjectileManagerStart:
    ; declare and initialise the full projectile pool
    rts

UpdateProjectileManager:
    ; iterate through every projectile being managed
    ; update any that require it
    rts

UpdateProjectile:
    rts

CollisionProjectileCheck:
    rts

InitialiseProjectilePool:
    ; iterate through the array and set everything up
    rts

; function for creating a projectile with a set type and initial position/velocity
SpawnProjectile:
    rts
