class Department {
  final String name;
  final String code;

  const Department(this.name, this.code);

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      json['name'] as String? ?? '',
      json['code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
  };
}

const List<Department> defaultDepartments = [
  Department('Computer Science and Engineering', 'CSE'),
  Department('Information Technology', 'IT'),
  Department('Artificial Intelligence and Data Science', 'AIDS'),
  Department('Artificial Intelligence and Machine Learning', 'AIML'),
  Department('Computer Science and Business Systems', 'CSBS'),
  Department('Cyber Security', 'CYS'),
  Department('Electronics and Communication Engineering', 'ECE'),
  Department('Electrical and Electronics Engineering', 'EEE'),
  Department('Electronics and Instrumentation Engineering', 'EIE'),
  Department('Mechanical Engineering', 'MECH'),
  Department('Civil Engineering', 'CIVIL'),
  Department('Chemical Engineering', 'CHEM'),
  Department('Biomedical Engineering', 'BME'),
  Department('Biotechnology', 'BT'),
  Department('Automobile Engineering', 'AUTO'),
  Department('Aeronautical Engineering', 'AERO'),
  Department('Food Technology', 'FT'),
  Department('Agricultural Engineering', 'AGRI'),
  Department('Robotics and Automation', 'RA'),
  Department('Internet of Things', 'IOT'),
];

const List<String> regulations = ['R2025', 'R2023', 'R2022', 'R2021'];

const List<int> semesters = [1, 2, 3, 4, 5, 6, 7, 8];
