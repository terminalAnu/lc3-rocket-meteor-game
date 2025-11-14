# lc3-rocket-meteor-game
Originally created for a Computer Systems course (COMP 2280).

This project is a small LC-3 Assembly game I built for COMP 2280. It runs entirely in the LC-3 simulator and turns a simple 20×6 ASCII grid into a tiny universe where you fly a rocket and dodge incoming meteors. 
You control the rocket with W, A, S, and D while a meteor slides across the screen, changing lanes as it goes. If you survive long enough, your score climbs reach 9 points and you win. Slip up and collide, and it’s game over.

What makes this project fun (and painful) is that everything is coded manually in LC-3 Assembly: screen drawing, movement logic, collision detection, score tracking, even a little pseudo-random generator for the meteor’s path. No shortcuts. No high-level conveniences. Just registers, memory-mapped I/O, and lots of debugging.

It’s low-level, a bit chaotic, and honestly one of the most fun (and WEIRDLY challenging) projects I’ve coded. 
