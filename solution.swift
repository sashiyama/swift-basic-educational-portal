import Foundation

// === [models] begin ===
class Account {
    let name: String
    let password: String
    static var all: [Account] = AccountImporter().accounts

    init(name: String, password: String) {
        self.name = name
        self.password = password
    }

    static func findBy(name: String, password: String) -> Account? {
        let predicate: (Account) -> Bool = { account in account.name == name && account.password == password }
        return Account.all.first(where: predicate)
    }
}

class Student {
    enum Gender: String {
        case male, female, unknown
    }

    let studentID: String
    let name: String
    let gender: Gender
    let grade: Int
    let address: String
    let admissionYear: Int
    let courses: [String]
    static var all: [Student] = StudentImporter().students

    init(studentID: String, name: String, gender: Gender, grade: Int, address: String, admissionYear: Int, courses: [String]) {
        self.studentID = studentID
        self.name = name
        self.gender = gender
        self.grade = grade
        self.address = address
        self.admissionYear = admissionYear
        self.courses = courses
    }

    static func findBy(studentID: String) -> Student? {
        let predicate: (Student) -> Bool = { student in student.studentID == studentID }
        return Student.all.first(where: predicate)
    }

    static func printAll() {
        print()
        for (index, student) in Student.all.enumerated() {
            print("\(index+1)): \(student.name): \(student.studentID)")
        }
        print()
    }

    func rank() -> Int {
        let scores = StudentCourse.gpaGroupByStudentID()

        if scores.isEmpty {
            return -1
        }

        guard let gpa = scores[self.studentID] else {
            return -1
        }

        var win = 0
        for item in scores {
            if gpa > item.value {
                win += 1
            }
        }

        return scores.count - win
    }
}

class Course {
    let courseID: String
    let name: String
    static var all: [Course] = CourseImporter().courses

    init(courseID: String, name: String) {
        self.courseID = courseID
        self.name = name
    }

    static func whereBy(courseIDs: [String]) -> [Course] {
        return Course.all.filter({ course in courseIDs.contains(course.courseID) })
    }

    static func findBy(courseID: String) -> Course? {
        return Course.all.first(where: { course in course.courseID == courseID })
    }

    static func printCourses(student: Student, courses: [Course]) {
        print()
        print("Hi \(student.name),")
        print("You have taken the following courses:")
        for (index, course) in courses.enumerated() {
            print("\(index+1))    \(course.courseID): \(course.name)")
        }
        print()
    }

    static func printAll() {
        print()
        for (index, course) in Course.all.enumerated() {
            print("\(index+1)):  \(course.name)")
        }
        print()
    }
}

class StudentCourse {
    let studentID: String
    let courseID: String
    let mark: Int
    static var all: [StudentCourse] = StudentCourseImporter().studentCourses

    init(studentID: String, courseID: String, mark: Int) {
        self.studentID = studentID
        self.courseID = courseID
        self.mark = mark
    }

    static func whereBy(student: Student, courses: [Course]) -> [StudentCourse] {
        return StudentCourse.all.filter({ studentCourse in studentCourse.studentID == student.studentID && courses.contains(where: { course in course.courseID == studentCourse.courseID }) })
    }

    static func printStudentCourse(studentCourses: [StudentCourse]) {
        print()

        for (index, studentCourse) in studentCourses.enumerated() {
            guard let course = Course.findBy(courseID: studentCourse.courseID) else {
                continue
            }

            print("\(index+1))    \(course.name):\(studentCourse.mark)")
        }

        print("YOUR GPA IS: \(gpa(studentCourses: studentCourses))")

        print()
    }

    static func printGpa(studentCourses: [StudentCourse]) {
        if studentCourses.isEmpty {
            return
        }

        guard let student = Student.findBy(studentID: studentCourses[0].studentID) else {
            return
        }

        let message = """

        Hi \(student.name),
        Your GPA is \(gpa(studentCourses: studentCourses))

        """

        print(message)
    }

    static func printGpaAndRank(studentCourses: [StudentCourse]) {
        if studentCourses.isEmpty {
            return
        }

        guard let student = Student.findBy(studentID: studentCourses[0].studentID) else {
            return
        }

        let message = """

        Hi \(student.name)
        Your GPA is \(gpa(studentCourses: studentCourses)) and therefore your rank is \(student.rank()).

        """

        print(message)
    }

    static func gpaGroupByStudentID() -> [String:Double] {
        var result: [String:Double] = [:]
        var numOfSum: [String:Int] = [:]

        for studentCourse in StudentCourse.all {
            if result[studentCourse.studentID] != nil && numOfSum[studentCourse.studentID] != nil {
                result[studentCourse.studentID] = result[studentCourse.studentID]! + Double(studentCourse.mark)
                numOfSum[studentCourse.studentID]! += 1
            } else {
                result[studentCourse.studentID] = Double(studentCourse.mark)
                numOfSum[studentCourse.studentID] = 1
            }
        }

        for studentCourse in StudentCourse.all {
            guard let sum = result[studentCourse.studentID], let numOfSum = numOfSum[studentCourse.studentID] else {
                continue
            }

            result[studentCourse.studentID] = sum / Double(numOfSum)
        }

        return result
    }

    private static func gpa(studentCourses: [StudentCourse]) -> Double {
        var marks = 0.0

        for studentCourse in studentCourses {
            marks += Double(studentCourse.mark)
        }

        return marks / (Double(studentCourses.count) == 0 ? 1 : Double(studentCourses.count))
    }
}

// === [models] end ===

// === [UI] begin ===
class LoginForm {
    var name: String = ""
    var password: String = ""
    var currentAccount: Account?
    var currentStudent: Student? {
        print("Please enter your student ID: ", terminator: "")

        guard let studentID = readLine() else {
            return nil
        }

        return Student.findBy(studentID: studentID)
    }

    func login() {
        while true {
            print(Message.loginPrompt)

            print("Username: ", terminator: "")
            guard let name = readLine() else {
                return
            }
            self.name = name

            print("Password: ", terminator: "")
            guard let password = readLine() else {
                return
            }
            self.password = password

            self.currentAccount = authenticate()
            if self.currentAccount != nil {
                print(Message.welcome)
                break
            } else {
                print(Message.loginFailure)
            }
        }
    }

    func authenticate() -> Account? {
        return Account.findBy(name: self.name, password: self.password)
    }
}

class EnrollCertificate {
    let account: Account
    let student: Student

    init(account: Account, student: Student) {
        self.account = account
        self.student = student
    }

    func printCertificate() {
        let certificate = """

    Dear Sir/Madam,

    This is to certify that \(student.name) with student id \(student.studentID) is a student at grade \(student.grade) at CICCC. He was admitted to our college in \(student.admissionYear) and has taken \(student.courses.count) course(s). Currently he resides at \(student.address).

    If you have any question, please don’t hesitate to contact us.
    Thanks,
    Williams,

    """
        print(certificate)
    }
}

class OptionHandler {
    let account: Account
    let student: Student
    var option: Int = 9
    var logout: Bool = false

    init(account: Account, student: Student) {
        self.account = account
        self.student = student
    }

    func handle() {
        while true {
            askOption()

            switch self.option {
            case 1:
                EnrollCertificate(account: self.account, student: self.student).printCertificate()
            case 2:
                Course.printCourses(student: self.student, courses: Course.whereBy(courseIDs: self.student.courses))
            case 3:
                let studentCourses = StudentCourse.whereBy(student: self.student, courses: Course.whereBy(courseIDs: self.student.courses))
                StudentCourse.printStudentCourse(studentCourses: studentCourses)
            case 4:
                let studentCourses = StudentCourse.whereBy(student: self.student, courses: Course.whereBy(courseIDs: self.student.courses))
                StudentCourse.printGpa(studentCourses: studentCourses)
            case 5:
                let studentCourses = StudentCourse.whereBy(student: self.student, courses: Course.whereBy(courseIDs: self.student.courses))
                StudentCourse.printGpaAndRank(studentCourses: studentCourses)
            case 6:
                Course.printAll()
            case 7:
                Student.printAll()
            case 8:
                self.logout = true
                return
            case 9:
                return
            default:
                return
            }
        }

    }

    private func askOption() {
        print(Message.selectOptions)

        guard let value = readLine() else {
            return
        }

        guard let value = Int(value) else {
            return
        }

        self.option = value
    }
}

struct Message {
    static let loginPrompt = """

************************************************************
Please enter your account to login:
************************************************************

"""
    static let welcome = """

************************************************************
Welcome to Cornerstone International College of Canada.
************************************************************

"""
    static let loginFailure = """

************************************************************
Your account does not exist. Please try again!
************************************************************

"""
    static let selectOptions = """

************************************************************
Select from the options:
************************************************************
—-[1] Print my enrolment certificate
—-[2] Print my courses
—-[3] Print my transcript
—-[4] Print my GPA
—-[5] Print my ranking among all students in the college
—-[6] List all available courses
—-[7] List all students
-—[8] Logout
-—[9] Exit
************************************************************

"""
}

// === [UI] end ===

// ==== [importers] begin ====

class StudentCourseImporter {
    let filename: String = "StudentsCourses"
    let filetype: String = "txt"
    var studentCourses: [StudentCourse] {
        var studentCoursesList: [StudentCourse] = []
        var studentCoursesDicList: [[String:String]] = []
        var studentCourseIndex = 0

        for item in FileReader(filename: filename, filetype: filetype).lines {
            if item[0].contains("studentID") {
                studentCoursesDicList.append(["studentID": item[1]])
            } else if item[0].contains("courseID") {
                studentCoursesDicList[studentCourseIndex]["courseID"] = item[1]
            } else if item[0].contains("mark") {
                studentCoursesDicList[studentCourseIndex]["mark"] = item[1]
                studentCourseIndex += 1
            }
        }

        for studentCoursesItem in studentCoursesDicList {
            guard let studentID = studentCoursesItem["studentID"], let courseID = studentCoursesItem["courseID"], let markStr = studentCoursesItem["mark"] else {
                continue
            }

            var mark = 0
            if Int(markStr) != nil {
                mark = Int(markStr)!
            }

            studentCoursesList.append(StudentCourse(studentID: studentID, courseID: courseID, mark: mark))
        }

        return studentCoursesList
    }
}

class CourseImporter {
    let filename: String = "Courses"
    let filetype: String = "txt"
    var courses: [Course] {
        var coursesList: [Course] = []
        var coursesDicList: [[String:String]] = []
        var courseIndex = 0

        for item in FileReader(filename: filename, filetype: filetype).lines {
            if item[0].contains("courseID") {
                coursesDicList.append(["courseID": item[1]])
            } else if item[0].contains("name") {
                coursesDicList[courseIndex]["name"] = item[1]
                courseIndex += 1
            }
        }

        for coursesItem in coursesDicList {
            guard let courseID = coursesItem["courseID"], let name = coursesItem["name"] else {
                continue
            }

            coursesList.append(Course(courseID: courseID, name: name))
        }

        return coursesList
    }
}

class StudentImporter {
    let filename: String = "Students"
    let filetype: String = "txt"
    var students: [Student] {
        var studentsList: [Student] = []
        var studentsDicList: [[String:String]] = []
        var studentIndex = 0

        for item in FileReader(filename: filename, filetype: filetype).lines {
            if item[0].contains("studentID") {
                studentsDicList.append(["studentID": item[1]])
            } else if item[0].contains("name") {
                studentsDicList[studentIndex]["name"] = item[1]
            } else if item[0].contains("gender") {
                studentsDicList[studentIndex]["gender"] = item[1]
            } else if item[0].contains("grade") {
                studentsDicList[studentIndex]["grade"] = item[1]
            } else if item[0].contains("address") {
                studentsDicList[studentIndex]["address"] = item[1]
            } else if item[0].contains("admission_year") {
                studentsDicList[studentIndex]["admissionYear"] = item[1]
            } else if item[0].contains("courses") {
                studentsDicList[studentIndex]["courses"] = item[1]
                studentIndex += 1
            }
        }

        for studentsItem in studentsDicList {
            guard let studentID = studentsItem["studentID"], let name = studentsItem["name"], let gender = studentsItem["gender"], let gradeStr = studentsItem["grade"], let address = studentsItem["address"], let admissionYearStr = studentsItem["admissionYear"], let coursesStr = studentsItem["courses"] else {
                continue
            }

            var genderEnum: Student.Gender
            if Student.Gender(rawValue: gender) != nil {
                genderEnum = Student.Gender(rawValue: gender)!
            } else {
                genderEnum = .unknown
            }

            var grade = 0
            if Int(gradeStr) != nil {
                grade = Int(gradeStr)!
            }

            var admissionYear = 2000
            if Int(admissionYearStr) != nil {
                admissionYear = Int(admissionYearStr)!
            }

            let courses = coursesStr.components(separatedBy: ",")

            studentsList.append(
                Student(
                    studentID: studentID,
                    name: name,
                    gender: genderEnum,
                    grade: grade,
                    address: address,
                    admissionYear: admissionYear,
                    courses: courses
                )
            )
        }

        return studentsList
    }
}

class AccountImporter {
    let filename: String = "Accounts"
    let filetype: String = "txt"
    var accounts: [Account] {
        var accountsList: [Account] = []
        var accountsDicList: [[String:String]] = []
        var accountIndex = 0

        for item in FileReader(filename: filename, filetype: filetype).lines {
            if item[0].contains("User") {
                accountsDicList.append(["username": item[1]])
            } else if item[0].contains("Pass") {
                accountsDicList[accountIndex]["password"] = item[1]
                accountIndex += 1
            }
        }

        for accountsItem in accountsDicList {
            guard let username = accountsItem["username"], let password = accountsItem["password"] else {
                continue
            }
            accountsList.append(Account(name: username, password: password))
        }

        return accountsList
    }
}

class FileReader {
    let filename: String
    let filetype: String
    var lines: [[String]] {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }

        let path = dir.appendingPathComponent("\(filename).\(filetype)")

        var lineList: [[String]] = []

        do {
            let contents = try String(contentsOf: path, encoding: .utf8)
            lineList = contents.components(separatedBy: "\n")
                .filter({ s in s != "" })
                .map({ s in s.components(separatedBy: ":")
                .map({ s in
                    var cs = s
                    cs.removeAll(where: {c in c == "\""})
                    return cs
                })})
        } catch {
            return []
        }

        return lineList
    }

    init(filename: String, filetype: String) {
        self.filename = filename
        self.filetype = filetype
    }
}

// ==== [importers] end ====

func main() {
    while true {
        let loginForm = LoginForm()
        loginForm.login()

        guard let account = loginForm.currentAccount else {
            return
        }

        guard let student = loginForm.currentStudent else {
            return
        }

        sleep(2)

        let optionHandler = OptionHandler(account: account, student: student)
        optionHandler.handle()

        if !optionHandler.logout {
            break
        }
    }
}

main()
