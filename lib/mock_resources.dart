import 'package:aidsense_app/models.dart';

final List<Resource> mockResources = [
  Resource(
    id: '1',
    name: "St Joseph's Home",
    address: "81 York St, Jersey City, NJ 07302",
    type: "Shelter",
    tags: ["Beds", "Warm meals"],
    latitude: 40.71688634345244, 
    longitude: -74.03769481609896,
    phone: '(201) 413-9280',
    website: 'https://yorkstreetproject.org/our-programs/st-josephs-home/'
  ),
  Resource(
    id: '2',
    name: "The Jersey City Clinic",
    address: "1 Jackson Sq, Jersey City, NJ 07305",
    type: "Clinic",
    tags: ["Medical help", "Checkups"],
    latitude: 40.712378161806676,
    longitude: -74.07820608959999,
    website: 'https://www.jerseycitynj.gov/cityhall/health/preventativehealth',
    phone: '(201) 547-5535'
  ),
    Resource(
    id: '3',
    name: "Mount Pisgah AME Food Pantry",
    address: "354 Forrest St, Jersey City, NJ 07304",
    type: "Food bank",
    tags: ["Groceries", "Free meals"],
    latitude: 40.7144747152555,
    longitude: -74.07840710912085,
    website: 'https://www.wearemtpisgah.org/',
    phone: '(201) 435-3680'
  ),
];
