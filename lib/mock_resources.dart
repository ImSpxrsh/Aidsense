import 'package:aidsense_app/models.dart';

final List<Resource> mockResources = [
  Resource(
      id: '1',
      name: "St Joseph's Home",
      address: "",
      type: "Shelter",
      tags: ["Beds", "Warm meals"],
      latitude: 40.71688634345244,
      longitude: -74.03769481609896,
      phone: '',
      website: 'https://yorkstreetproject.org/our-programs/st-josephs-home/'),
  Resource(
      id: '2',
      name: "The Jersey City Clinic",
      address: "",
      type: "Clinic",
      tags: ["Medical help", "Checkups"],
      latitude: 40.712378161806676,
      longitude: -74.07820608959999,
      website:
          'https://www.jerseycitynj.gov/cityhall/health/preventativehealth',
      phone: ''),
  Resource(
      id: '3',
      name: "Mount Pisgah AME Food Pantry",
      address: "",
      type: "Food bank",
      tags: ["Groceries", "Free meals"],
      latitude: 40.7144747152555,
      longitude: -74.07840710912085,
      website: 'https://www.wearemtpisgah.org/',
      phone: ''),
];
