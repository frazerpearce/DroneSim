extends RefCounted
# Gate width/height are clear openings; all coordinates are metres.
const COURSES := [
 {"id":"hangar-01-v1","name":"First Flight","difficulty":"Beginner","width":5.0,"height":4.0,"hint":"Wide gates, level flight and gentle turns.","points":[Vector3(0,3,2),Vector3(0,3,-5),Vector3(0,3,-12),Vector3(4,3,-18),Vector3(8,3,-10),Vector3(8,3,2)]},
 {"id":"hangar-02-v1","name":"Gentle Slalom","difficulty":"Easy","width":4.8,"height":3.8,"hint":"Learn to brake and change lateral direction.","points":[Vector3(-3,3,1),Vector3(3,3,-6),Vector3(-3,3,-13),Vector3(3,3,-21),Vector3(10,3,-12),Vector3(9,3,2)]},
 {"id":"hangar-03-v1","name":"Step Up","difficulty":"Easy","width":4.6,"height":3.6,"hint":"Climb progressively, then descend under control.","points":[Vector3(0,3,1),Vector3(-5,5,-7),Vector3(-5,7,-17),Vector3(5,7,-21),Vector3(10,5,-10),Vector3(8,3,4)]},
 {"id":"hangar-04-v1","name":"Hangar Circuit","difficulty":"Moderate","width":4.4,"height":3.4,"hint":"The original six-gate course with mixed heights.","points":[Vector3(0,3,0),Vector3(-7,4,-10),Vector3(0,5,-20),Vector3(9,4,-10),Vector3(10,3,2),Vector3(8,2.5,12)]},
 {"id":"hangar-05-v1","name":"Switchbacks","difficulty":"Moderate","width":4.2,"height":3.4,"hint":"Repeated tight direction changes test momentum control.","points":[Vector3(-6,3,1),Vector3(-10,4,-10),Vector3(-3,4,-18),Vector3(4,4,-10),Vector3(11,4,-18),Vector3(13,3,-4),Vector3(8,3,8)]},
 {"id":"hangar-06-v1","name":"Rollercoaster","difficulty":"Challenging","width":4.0,"height":3.2,"hint":"Alternate climbs and descents through a long circuit.","points":[Vector3(0,3,0),Vector3(-6,7,-8),Vector3(-6,3,-19),Vector3(3,8,-22),Vector3(11,4,-13),Vector3(9,8,-2),Vector3(5,3,9)]},
 {"id":"hangar-07-v1","name":"Precision Run","difficulty":"Challenging","width":2.8,"height":2.8,"hint":"Smaller openings reward accurate alignment over speed.","points":[Vector3(-3,3,0),Vector3(-8,4,-9),Vector3(-4,5,-20),Vector3(5,5,-19),Vector3(11,4,-8),Vector3(8,3,5),Vector3(8,2.5,13)]},
 {"id":"hangar-08-v1","name":"High Wire","difficulty":"Hard","width":3.0,"height":2.8,"hint":"Climb above the circuit, hold height, then descend to land.","points":[Vector3(0,4,0),Vector3(-6,8,-7),Vector3(-8,12,-18),Vector3(0,12,-23),Vector3(10,12,-15),Vector3(12,9,-4),Vector3(8,6,7),Vector3(8,3,13)]},
 {"id":"hangar-10-v1","name":"Master Circuit","difficulty":"Expert","width":2.2,"height":2.4,"hint":"A long precision circuit combining altitude changes and reversals.","points":[Vector3(-4,3,1),Vector3(-10,6,-6),Vector3(-5,10,-15),Vector3(4,8,-23),Vector3(12,4,-17),Vector3(5,7,-9),Vector3(-4,4,-4),Vector3(2,9,4),Vector3(11,6,9),Vector3(8,2.5,14)]},
 {"id":"hangar-09-v1","name":"Technical Slalom","difficulty":"Expert","width":2.5,"height":2.6,"hint":"Narrow gates, lateral reversals and changing height.","points":[Vector3(-4,3,1),Vector3(3,5,-5),Vector3(-5,3,-12),Vector3(3,6,-20),Vector3(11,4,-14),Vector3(5,6,-7),Vector3(12,3,1),Vector3(6,4,9),Vector3(8,2.5,14)]}
]

static func id_at(index: int) -> String:
 return COURSES[index].id

static func index_of(id: String) -> int:
 for i in range(COURSES.size()):
  if COURSES[i].id==id: return i
 return 0
