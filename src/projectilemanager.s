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

    ; test draw a projectile to show that the manager is running
    move.l      #projectile_gfx,a0
    move.l      #projectile_mask,a1
    move.l      draw_buffer,a2
    move.w      #32,d0
    move.w      #32,d1
    move.w      #16,d2
    move.w      #16,d3
    move.w      #0,d4
    move.w      #0,d5
    move.w      #16,a3
    move.w      #16,a4

    bsr         draw_bob

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
