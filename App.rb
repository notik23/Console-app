require 'sqlite3'
require 'date'
require 'benchmark'

#создание БД
db = SQLite3::Database.open('Base.db')
db.execute('
    CREATE TABLE IF NOT EXISTS directory (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ФИО TEXT NOT NULL,
      Дата_рождения TEXT NOT NULL, 
      Пол TEXT NOT NULL
    )
')
db.close

#вывод записей из таблицы, добавление поля с возрастом в хеш
def read_notes
  db = SQLite3::Database.open('Base.db')
  db.results_as_hash = true
  notes = db.execute('SELECT * FROM directory ORDER BY ФИО ASC')
  db.close

  notes.map do |note|
    birth_date = Date.parse(note['Дата_рождения'])
    age = how_age(birth_date)
    note['Возраст'] = age
    note
  end
end

#рассчет возраста 
def how_age(birth_date)
  today = Date.today
  age = today.year - birth_date.year
  age -= 1 if (today.month < birth_date.month || (today.month == birth_date.month && today.day < birth_date.day))
  return age
end

#класс сотрудник
class Employee

  attr_accessor :name, :date, :sex

  def initialize(name, date, sex)
    @name = name
    @date = date
    @sex = sex
  end

  #метод сохранения записи в таблицу
  def save_note
    db = SQLite3::Database.open('Base.db')
    db.results_as_hash = true
    db.execute('INSERT INTO directory (ФИО, Дата_рождения, Пол) VALUES (?, ?, ?)', [name, date, sex])
    db.close
  end

  #пакетная отправка отправка данных в таблицу при автоматическом заполнении
  def self.batch_insert(employees)
    db = SQLite3::Database.open('Base.db')
    db.results_as_hash = true
    db.transaction do
      employees.each do |emp|
        db.execute('INSERT INTO directory (ФИО, Дата_рождения, Пол) VALUES (?, ?, ?)', 
                  [emp.name, emp.date, emp.sex])
      end
    end
    db.close
  end

  #генерация значений длля автоматического заполнения
  def self.generate_random_name
    first_names = ['Ivan', 'Petr', 'Michael', 'Kristina', 'James', 'Anna', 'George', 'Bob']
    last_names = ['Smith', 'Johnson', 'Williams', 'Jones', 'Brown', 'Davis', 'Miller']
    "#{last_names.sample} #{first_names.sample}"
  end

  def self.generate_random_date
    year = rand(1950..2000)
    month = rand(1..12)
    day = rand(1..28)
    "#{year}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  end

  def self.generate_random_sex
    ['Male', 'Female'].sample
  end

  #генерация массива объектов Employees
  def self.generate_employees(count)
    employees = []
    count.times do
      name = generate_random_name
      date = generate_random_date
      sex = generate_random_sex
      employees << Employee.new(name, date, sex)
    end
    employees
  end
  
  #генерация массива объектов Employees мужского пола с фамилей на F
  def self.generate_employees_with_f_surname(count)
    employees = []
    count.times do
      first_name = ['John', 'Michael', 'James', 'George', 'William'].sample
      last_name = "F#{['ufu', 'rank', 'ord', 'rost', 'ox'].sample}"
      patronymic = ['Ivanovich', 'Lordovich', 'Petrovich'].sample
      name = "#{last_name} #{first_name} #{patronymic}"
      date = generate_random_date
      sex = 'Male'
      employees << Employee.new(name, date, sex)
    end
    employees
  end
end

#вывод выборки записей
def filtering_notes
  db = SQLite3::Database.open('Base.db')
  db.results_as_hash = true
  notes = db.execute("SELECT * FROM directory WHERE ФИО LIKE 'F%' AND Пол = 'Male'")
  db.close
  return notes
end

loop do

  puts "Выберите действие (укажите цирфу):\n1. Создать новую запись\n2. Вывести список\n3. Автоматическое заполнение справочника\n4. Вывести выборку по критерию\n5. Завершить программу"
  choice = gets.chomp.to_i

  case choice 
    when 1
      loop do
        puts "Введите ФИО, дату рождения и пол (Enter для завершения ввода): "
        input = gets.chomp

        if input.empty?
          puts "Ввод завершен."
          break
        end

        #разбитие введенной строки для считывания значений
        parts = input.split(' ')

        name = parts[0..2].join(' ') 
        date = parts[3]
        sex = parts[4]

        employee = Employee.new(name, date, sex)
        employee.save_note
      end
    when 2 

      notes = read_notes
      
      if !notes.empty?
        puts "=" * 95
        notes.each do |note|
          puts "ID: #{note['id']} || ФИО: #{note['ФИО']};  Дата рождения: #{note['Дата_рождения']}; Пол: #{note['Пол']}; Полных лет: #{note['Возраст']}"
        end
        puts "=" * 95
      else 
        puts "Ещё нет ни одной записи"
      end

    when 3 
      #автоматическое заполнение таблицы
      puts "Заполнение..."
      employees = Employee.generate_employees(1_000_000)
      Employee.batch_insert(employees)

      employees_with_f_surname = Employee.generate_employees_with_f_surname(100)
      Employee.batch_insert(employees_with_f_surname)
      
      puts "Автоматическое заполнение завершено!"

    when 4 
      notes = filtering_notes
      if !notes.empty?
        puts "=" * 95
        notes.each do |note|
          puts "ID: #{note['id']} || ФИО: #{note['ФИО']}; Дата рождения: #{note['Дата_рождения']}; Пол: #{note['Пол']}"
        end
        puts "=" * 95

        time = Benchmark.measure {filtering_notes}.real
        puts "Время выполнения: #{time.round(4)} секунд"
        puts "=" * 95

      else 
        puts "Записи не найдены"
      end
    when 5
      puts "Работа завершена"
      break
    else 
      puts "Недопустимый ввод"
  end 
end
