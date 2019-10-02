This is a verilog project I made along with another student for an electrical engineering class. It is a snake game that uses VGA graphics, and is meant to be run on a nexys3 board. Below is the project report we made for the class.

EE354L Project Report

Snake

Alexander Baker (CECS) and Henry Morales (EE)

Spring 2019

**Abstract:**

**       ** In this project, we implemented the popular game Snake. A simple game where the user must maneuver a block around the screen consuming food while avoiding the border and itself. With every piece consumed the snake grows longer, thus raising the difficulty of the game.

**Background:**

        In this project, the file we utilized was the vga\_demo.v file. We used this file as a building block for our project. We also utilized some code from earlier labs to control things such as the button presses and writing the testbench. Additionally, to understand more about how to create our own design using VGA, we looked at some online examples of people implementing different VGA designs in verilog.

**Design:**

**       ** The first thing we implemented in this design was the movement of the block. We needed the block, or rather the head of the snake, to move in a way where it would not be able to move in the opposing direction it is currently moving in. For example: if the snake is moving to the right, it should not be able to go straight to the left. The movement should be restricted to a 90 degree turn either up or down. To successfully accomplish this, we devised a simple state machine to restrict the movements in this manner. We settled on 6 states: initial, left, right, up, down, and death state. We begin in the initial state upon reset and then depending on the button pressed on the FPGA (BtnL, BtnU, etc) we transfer to either of the direction states (left, right, etc..) and continue moving in the direction that state points in until another button is pressed. The button that would need to be pressed to move the snake in another direction is always restricted in the fashion mentioned earlier. For example: the up state only accepts the left or right buttons in order to transition to a new state. Once we perfected the movements of the head of the snake, we began working on the random food generation / consuming the food.

        To randomly generate the location of the food after it has been consumed, we used a pseudo-random number generator module to produce coordinates for the food within the playing area. When the head of the snake collides with the food, this module is called upon to update the coordinates of the food to a new location.

        In order for the snake to grow when it eats the food, we used a size 32 array of coordinates to store locations for the snake. Every time the head of the snake moves, these coordinates are updated with a for loop so that each coordinate takes the location of the element that came before it in the array. By setting the first element of the array to be the same location as the snake head, this means that we are always storing the coordinates of the last 32 places the snake head has been. In order to display a varying number of these coordinates (to simulate growth), we simply have a counter that increases when the food is eaten. Then, when displaying the snake and checking for collisions, we display all the coordinates from the array that are less than this counter. In our design, the maximum length of the snake is 32, which is long enough for most games. We would like to have made it larger, but we ran into memory and space allocation problems when we tried to increase the maximum size.

        The next step was to program the collisions. A collision occurs when two coordinates (for example the snakehead and the snakebody) are within a certain range of eachother. Every time the VGA clock would go to a new pixel, we would check to see if that pixel is within range of two coordinates that should imply a collision. If a collision occurs, this sets a flag and the appropriate steps are then taken to allow the game to proceed.

Once all these steps were completed we created a border that encompasses the play area of the snake. The width of the border was chosen to be 30 pixels all around. This is because we required the snake to move in a grid like fashion. We found that a border of this width with the snake moving 20 pixels per clock cycle restricted in this border allowed us to accomplish this. We then began working on the death of the snake. The snake needs to stop moving all together and reset once it either hits itself or the border. This is where the death state comes in, with a few simple lines we were able to use the collision checking strategy from above to update our state diagram to include lethal collisions with the border or the body of the snake.

**Testing:**

**       ** Once we had a somewhat working design for the game, we had to do a lot of testing to get rid of bugs. This was particularly challenging because a lot of the problems we encountered were due to increasing the size of the snake. So, in order to test our design, we would have to play the game enough to grow the snake to a certain point. We were running into an issue where the snake would randomly reset to size zero even if it had not yet reached its maximum size. After a lot of testing, we realized that this was due to a timing issue between two of our always blocks. Once the obvious bugs were sorted out, we each went through 30 or so runs of the game to ensure that there were no remaining issues.

**Conclusion:**

**       ** One idea for a way to increase the complexity of this design would be to add multiplayer. You could have two seperate players that each control their own snake head, and instead of looking for food they could be trying to destroy the other snake. This is actually something that we thought about doing for the project, but decided that given the allotted time, it made more sense to go with a single-player version.

        As far as labs go, I think one important change would be to make sure that students are keeping up, especially early in the Verilog learning process. I know that in our class, several students felt like they were not learning at the pace they should, and this became a bigger issue as the labs got more and more complex. Sometimes in lab it can be easy to just follow along with the instructor without really grasping all of the important concepts, and I think this is something that should be addressed in the future.
