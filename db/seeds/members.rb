members = [
  { first_name: "Maria",  middle_name: "Santos",    last_name: "Cruz",       suffix: nil,    gender: "female", civil_status: "married",  mobile_number: "09171234567", birth_date: Date.new(1985, 6, 15)  },
  { first_name: "Juan",   middle_name: "Dela",      last_name: "Reyes",     suffix: "Jr.",  gender: "male",   civil_status: "married",  mobile_number: "09182223344", birth_date: Date.new(1978, 3, 22)  },
  { first_name: "Elena",  middle_name: "Garcia",    last_name: "Villanueva", suffix: nil,    gender: "female", civil_status: "single",  mobile_number: "09051112233", birth_date: Date.new(1992, 11, 8)  },
  { first_name: "Jose",   middle_name: "Rizal",     last_name: "Mercado",   suffix: nil,    gender: "male",   civil_status: "single",  mobile_number: "09331234567", birth_date: Date.new(1990, 7, 30)   },
  { first_name: "Ana",    middle_name: "Luna",      last_name: "Dimagiba",  suffix: nil,    gender: "female", civil_status: "widowed", mobile_number: "09221112233", birth_date: Date.new(1975, 1, 12)  },
  { first_name: "Pedro",  middle_name: "M.",        last_name: "Santos",    suffix: nil,    gender: "male",   civil_status: "married",  mobile_number: "09163334455", birth_date: Date.new(1982, 9, 5)   },
  { first_name: "Sofia",  middle_name: "C.",        last_name: "Gonzales",  suffix: nil,    gender: "female", civil_status: "single",  mobile_number: "09082223344", birth_date: Date.new(1995, 4, 18)  },
  { first_name: "Carlos", middle_name: "B.",        last_name: "Yulo",      suffix: nil,    gender: "male",   civil_status: "married",  mobile_number: "09194445566", birth_date: Date.new(1980, 12, 1)  },
  { first_name: "Luz",    middle_name: "V.",        last_name: "Macapagal", suffix: nil,    gender: "female", civil_status: "married",  mobile_number: "09171112233", birth_date: Date.new(1988, 8, 25)  },
  { first_name: "Ramon",  middle_name: "D.",        last_name: "Alcantara", suffix: nil,    gender: "male",   civil_status: "divorced", mobile_number: "09265556677", birth_date: Date.new(1973, 5, 14)  },
  { first_name: "Isabel", middle_name: "T.",        last_name: "Samson",    suffix: nil,    gender: "female", civil_status: "married",  mobile_number: "09183334455", birth_date: Date.new(1991, 2, 28)  },
  { first_name: "Antonio", middle_name: "L.",       last_name: "Lopez",     suffix: "III",  gender: "male",   civil_status: "single",  mobile_number: "09334445566", birth_date: Date.new(1994, 10, 7)  },
  { first_name: "Carmen", middle_name: "P.",        last_name: "Natividad", suffix: nil,    gender: "female", civil_status: "widowed", mobile_number: "09221114455", birth_date: Date.new(1970, 6, 20)  },
  { first_name: "Victor", middle_name: "S.",        last_name: "Mendoza",   suffix: nil,    gender: "male",   civil_status: "married",  mobile_number: "09175556677", birth_date: Date.new(1983, 4, 9)   },
  { first_name: "Lorna",  middle_name: "R.",        last_name: "Fernandez", suffix: nil,    gender: "female", civil_status: "single",  mobile_number: "09092223344", birth_date: Date.new(1997, 1, 3)   },
  { first_name: "Danilo", middle_name: "E.",        last_name: "Rivera",    suffix: nil,    gender: "male",   civil_status: "married",  mobile_number: "09186667788", birth_date: Date.new(1976, 11, 30) },
  { first_name: "Gloria", middle_name: "M.",        last_name: "Romero",    suffix: nil,    gender: "female", civil_status: "divorced", mobile_number: "09212223344", birth_date: Date.new(1981, 7, 16)  },
  { first_name: "Fernando", middle_name: "A.",      last_name: "Ramos",     suffix: nil,    gender: "male",   civil_status: "single",  mobile_number: "09335556677", birth_date: Date.new(1993, 9, 21)  },
  { first_name: "Rosario", middle_name: "B.",       last_name: "Castillo",  suffix: nil,    gender: "female", civil_status: "married",  mobile_number: "09178889900", birth_date: Date.new(1987, 3, 11)  },
  { first_name: "Miguel", middle_name: "N.",        last_name: "Angeles",   suffix: nil,    gender: "male",   civil_status: "single",  mobile_number: "09093334455", birth_date: Date.new(1996, 12, 19) },
]

members.each do |attrs|
  Member.find_or_create_by!(first_name: attrs[:first_name], last_name: attrs[:last_name]) do |m|
    m.assign_attributes(attrs)
  end
end

puts "Seeded #{Member.count} members"
