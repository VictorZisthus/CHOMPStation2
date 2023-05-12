/*
State Reference for R-Windows:
0 = Unanchored
1 = Anchored (Reinforced)
2 = Pried into frame (Reinforced)
3 = Fully Constructed
33 = Heated bolts & pried out of the frame
44 = Heated bolts unscrewed
55 = Fully Constructed, Heated bolts
*/

/obj/structure/window
	state = 3 //Setting it to the default state

/obj/structure/window/proc/cool_bolts()
	if(state == 55)
		state = 3
		visible_message("<span class='warning'>"The bolts on \the [src] look like they've cooled off..."</span>")
	else return

/obj/structure/window/attackby(obj/item/W as obj, mob/user as mob)
	if(!istype(W)) return//I really wish I did not need this

	// Fixing.
	if(istype(W, /obj/item/weapon/weldingtool) && user.a_intent == I_HELP)
		var/obj/item/weapon/weldingtool/WT = W
		if(health < maxhealth)
			if(WT.remove_fuel(1 ,user))
				to_chat(user, "<span class='notice'>You begin repairing [src]...</span>")
				playsound(src, WT.usesound, 50, 1)
				if(do_after(user, 40 * WT.toolspeed, target = src))
					health = maxhealth
			//		playsound(src, 'sound/items/Welder.ogg', 50, 1)
					update_icon()
					to_chat(user, "<span class='notice'>You repair [src].</span>")
		else
			visible_message("<span class='warning'>[user] begins heating the one-way screws on the [src]!</span>")
			playsound(src, WT.usesound, 75, 1)
			if(do_after(user, 40 * WT.toolspeed, target = src))
				remove_fuel(1 ,user)
				to_chat(user, "<span class='notice'>You heat the one-way screws on the [src].</span>")
				addtimer(CALLBACK(src, PROC_REF(cool_bolts)), 30 SECONDS)
		return

	// Slamming.
	if (istype(W, /obj/item/weapon/grab) && get_dist(src,user)<2)
		var/obj/item/weapon/grab/G = W
		if(istype(G.affecting,/mob/living))
			var/mob/living/M = G.affecting
			var/state = G.state
			qdel(W)	//gotta delete it here because if window breaks, it won't get deleted
			switch (state)
				if(<=1)
					M.visible_message("<span class='warning'>[user] slams [M] against \the [src]!</span>")
					M.apply_damage(7)
					hit(10)
				if(2)
					M.visible_message("<span class='danger'>[user] bashes [M] against \the [src]!</span>")
					if (prob(50))
						M.Weaken(1)
					M.apply_damage(10)
					hit(25)
				if(>= 3)
					M.visible_message("<span class='danger'><big>[user] crushes [M] against \the [src]!</big></span>")
					M.Weaken(5)
					M.apply_damage(20)
					hit(50)
			return

	if(W.flags & NOBLUDGEON) return

	if(W.is_screwdriver())
		if(reinf && state == 0)
			state = 1
			anchored = 1
			update_nearby_tiles(need_rebuild=1)
			update_nearby_icons()
			update_verbs()
			playsound(src, W.usesound, 75, 1)
			to_chat(user, "<span class='notice'>You have anchored the frame to the floor.</span>")
		else if(reinf && state == 1)
			state = 0
			anchored = 0
			update_nearby_icons()
			playsound(src, W.usesound, 75, 1)
			to_chat(user, "<span class='notice'>You have unanchored the frame from the floor.</span>")
		else if(reinf && state == 2)
			state = 3
			update_nearby_icons()
			playsound(src, W.usesound, 75, 1)
			to_chat(user, "<span class='notice'>You have fastened the window into the frame with one-way screws.</span>")
		else if(reinf && state == 2)
			state = 1
			update_nearby_icons()
			playsound(src, W.usesound, 75, 1)
			to_chat(user, "<span class='notice'>You have unfastened the window from the frame.</span>")
		else if(reinf && state == 55)
			state = 44
			update_nearby_icons()
			playsound(src, W.usesound, 75, 1)
			to_chat(user, "<span class='notice'>You have unfastened the heated screws from the frame.</span>")
		else if(reinf && state == 44)
			state = 3
			update_nearby_icons()
			playsound(src, W.usesound, 75, 1)
			to_chat(user, "<span class='notice'>You have fastened the one-way screws back into the frame.</span>")
		else if(!reinf)
			if(state == 3)
				state = 0
				anchored = 0
				update_nearby_tiles(need_rebuild=1)
				update_nearby_icons()
				update_verbs()
				playsound(src, W.usesound, 75, 1)
				to_chat(user, "<span class='notice'>You have unfastened the window from the floor.</span>")
			else
				state = 3
				anchored = 1
				update_nearby_icons()
				playsound(src, W.usesound, 75, 1)
				to_chat(user, "<span class='notice'>You have fastened the window onto the floor.</span>")
	else if(W.is_wirecutter())
		if(reinf && state == 33)
			state = 1
			playsound(src, W.usesound, 75, 1)
			to_chat(user, "<span class='notice'>You cut the reinforcment bars and the panel falls out of the way, exposing the frame screws.</span>")
	else if(W.is_crowbar())
		if(reinf && state == 1)
			state = 2
			playsound(src, W.usesound, 75, 1)
			to_chat(user, "<span class='notice'>You have pried the window into the frame.</span>")
		else if(reinf && state == 33)
			state = 44
			update_nearby_icons()
			playsound(src, W.usesound, 75, 1)
			to_chat(user, "<span class='notice'>You pry the window out back into the frame, covering the reinforcement bars.</span>")
		else if(reinf && state == 44)
			state = 33
			update_nearby_tiles(need_rebuild=1)
			update_nearby_icons()
			playsound(src, W.usesound, 75, 1)
			to_chat(user, "<span class='notice'>You have pried the window out of the frame, exposing the reinforcement bars.</span>")
	else if(W.is_wrench() && !anchored && (!state || !reinf))
		if(!glasstype)
			to_chat(user, "<span class='notice'>You're not sure how to dismantle \the [src] properly.</span>")
		else
			playsound(src, W.usesound, 75, 1)
			visible_message("<span class='notice'>[user] dismantles \the [src].</span>")
			var/obj/item/stack/material/mats = new glasstype(loc)
			if(is_fulltile())
				mats.set_amount(4)
			qdel(src)
	else if(istype(W, /obj/item/stack/cable_coil) && reinf && state == 0 && !istype(src, /obj/structure/window/reinforced/polarized))
		var/obj/item/stack/cable_coil/C = W
		if (C.use(1))
			playsound(src, 'sound/effects/sparks1.ogg', 75, 1)
			user.visible_message( \
				"<b>\The [user]</b> begins to wire \the [src] for electrochromic tinting.", \
				"<span class='notice'>You begin to wire \the [src] for electrochromic tinting.</span>", \
				"You hear sparks.")
			if(do_after(user, 20 * C.toolspeed, src) && state == 0)
				playsound(src, 'sound/items/Deconstruct.ogg', 50, 1)
				var/obj/structure/window/reinforced/polarized/P = new(loc, dir)
				if(is_fulltile())
					P.fulltile = TRUE
					P.icon_state = "fwindow"
				P.maxhealth = maxhealth
				P.health = health
				P.state = state
				P.anchored = anchored
				qdel(src)
	else if(istype(W,/obj/item/frame) && anchored)
		var/obj/item/frame/F = W
		F.try_build(src, user)
	else
		user.setClickCooldown(user.get_attack_speed(W))
		if(W.damtype == BRUTE || W.damtype == BURN)
			user.do_attack_animation(src)
			hit(W.force)
			if(health <= 7)
				anchored = FALSE
				update_nearby_icons()
				step(src, get_dir(user, src))
		else
			playsound(src, 'sound/effects/Glasshit.ogg', 75, 1)
		..()
	return