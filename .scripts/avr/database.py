import re
import sys
import subprocess
from .conf import mcu_dict


class NotDefinedMCUError(IOError):
    def __init__(self, name: str):
        self.error_text = 'MCU {} is not exists!'.format(name)

    def __str__(self):
        return self.error_text


class Database(object):
    def __init__(self):
        self.mcu_dict = mcu_dict

        regex = r'^\s*(\w*)\s*=\s*(\w*)$'
        result = subprocess.run(
            ['avrdude', '-c', 'usbasp', '-p', '.'],
            stderr=subprocess.PIPE,
        ).stderr.decode('utf-8')

        avrdude_mcu_dict = {
            match.group(2).lower(): match.group(1) for match in re.finditer(
                regex, result, re.MULTILINE
            )
        }

        for avrdude_mcu, avrdude_param in avrdude_mcu_dict.items():
            regex = re.compile(r'^{}[ahv]*$'.format(avrdude_mcu))
            for mcu in self.mcu_dict.keys():
                if regex.match(mcu):
                    self.mcu_dict[mcu].avrdude = avrdude_param

    def check_mcu_name(self, mcu):
        if mcu in self.mcu_dict:
            return True
        else:
            raise NotDefinedMCUError(mcu)
            return False

    def get_mcu(self, mcu):
        if self.check_mcu_name(mcu):
            return self.mcu_dict[mcu]
        else:
            return None

    def print_table(self, print_file=sys.stdout):
        """table.append('╔{}╗'.format('═'*width))
        table.append('║{}║'.format(head))
        table.append('╟{}╢'.format('─'*width))
        table.append('║{}║'.format(all_width_tag.format(str(all_memory))))
        table.append('║{}║'.format(use_width_tag.format(str(use_memory))))
        table.append('║{}║'.format(free_width_tag.format(str(all_memory - use_memory))))
        table.append('╚{}╝'.format('═'*width))"""

        format = ' ║ {:<18} │ {:<10} │ {:>10} │ {:>10} │ {:>10} ║'
        print(' ╔{}╤{}╤{}╤{}╤{}╗'.format('═'*20, '═'*12, '═'*12, '═'*12, '═'*12, file=print_file))

        print(format.format(
            'ATMEL NAME',
            'AVRDUDE',
            'RAM',
            'FLASH',
            'EEPROM',
        ), file=print_file)

        print(' ╠{}╪{}╪{}╪{}╪{}╣'.format('═'*20, '═'*12, '═'*12, '═'*12, '═'*12, file=print_file))

        for mcu, info in self.mcu_dict.items():
            print(format.format(
                mcu,
                '' if info.avrdude is None else str(info.avrdude),
                str(info.ram),
                str(info.flash),
                str(info.eeprom) if info.eeprom.value else '',
            ), file=print_file)

        print(' ╚{}╧{}╧{}╧{}╧{}╝'.format('═'*20, '═'*12, '═'*12, '═'*12, '═'*12, file=print_file))


Database = Database()