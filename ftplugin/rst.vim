if has('python')

python << EOF
# -*- encoding: utf-8 -*-
import vim
import re

def create_separarator(widths, char):
    """Generates a line to separate rows in a table.

     The parameter `widths' is a list indicating the width of each
     column. Instead the argument `char` is the character that is
     have to use for printing.

     The return value is a string.

     For example ::

         Create_separarator >>> ([2, 4], '-')
         '+ ---- + ------ +'
    """

    line = []

    for w in widths:
        line.append("+" + char * (w + 2))

    line.append("+")
    return ''.join(line)


def create_line(columns, widths):
    """Create a table row separating fields with a '|'.

     The argument `columns` is a list of cells that are
     want to print and plot widths `` is the width
     in each column. If the column is wider than the text
     to print empty spaces are added.

     For example ::

         Create_line >>> (['name', 'name'], [7, 10])
         '| Name | name |'
    """
    
    line = zip(columns, widths)
    result = []
    txt_encoding = vim.eval("g:rst_table_plugin_encoding")
    for text, width in line:
        text=text.decode('utf-8').encode(txt_encoding)
        line="| " + text.ljust(width) + " "
        result.append(line.decode(txt_encoding).encode('utf-8'))

    result.append("|")
    return ''.join(result)

def create_table(content):
    """Print a table in reStructuredText format.

     The argument `content` must be a list
     Cells.

     For example ::

         Create_table >>> print ([['software', 'vesion'], ['python', '2 .6 '], [' vim ', '7 .2']])

         +-----------+---------+
         | Software  | vesion  |
         +===========+=========+
         | Python i  | 2.6     |
         +-----------+---------+
         | Vim       | 7.2     |
         + ----------+---------+
    """

    # get all the columns of the table.
    columns = zip(*content)
    # calculates the maximum size that you need each column.
    txt_encoding = vim.eval("g:rst_table_plugin_encoding")
    widths = [max([len(x.decode('utf-8').encode(txt_encoding)) for x in i]) for i in columns]

    result = []

    result.append(create_separarator(widths, '-'))
    result.append(create_line(content[0], widths))
    result.append(create_separarator(widths, '='))

    for line in content[1:]:
        result.append(create_line(line, widths))
        result.append(create_separarator(widths, '-'))

    return '\n'.join(result)



def are_in_a_table(current_line):
    "Indicates whether the cursor is inside a table."
    return "|" in current_line or "+" in current_line

def are_in_a_paragraph(current_line):
    "Indicates whether the current line is part of any paragraph"
    return len(current_line.strip()) >= 1

def get_table_bounds(current_row_index, are_in_callback):
    """Gets the row number where the table begins and ends.

     `` are_in_callback argument must be a function
     to indicate whether a given line belongs or not
     to the table to be measured (or create).

     Returns two values as a tuple.
    """

    top = 0
    buffer = vim.current.buffer
    max = len(buffer)
    bottom = max - 1

    for a in range(current_row_index, top, -1):
        if not are_in_callback(buffer[a]):
            top = a + 1
            break

    for b in range(current_row_index, max):
        if not are_in_callback(buffer[b]):
            bottom = b - 1
            break

    return top, bottom

def remove_spaces(string):
    "Eliminate unnecessary spaces in a table row."
    return re.sub("\s\s+", " ", string)

def create_separators_removing_spaces(string):
    return re.sub("\s\s+", "|", string)


def extract_cells_as_list(string):
    "Extract text from a table row and returns it as a list."
    string = remove_spaces(string)
    return [item.strip() for item in string.split('|') if item]

def extract_table(buffer, top, bottom):
    content = []
    full_table_text = buffer[top:bottom]
    # selects only the lines that have cells with text.
    only_text_lines = [x for x in full_table_text if '|' in x]
    # cell extracts and discards unnecessary separators.
    return [extract_cells_as_list(x) for x in only_text_lines]

def extract_words_as_lists(buffer, top, bottom):
    "Generate a list of words to create a list."
    
    lines = buffer[top:bottom+1]
    return [create_separators_removing_spaces(line).split('|') for line in lines]


def copy_to_buffer(buffer, string, index):
    lines = string.split('\n')
    for line in lines:
        buffer[index] = line
        index += 1

def fix_table(current_row_index):
    """Set up a table so that all columns have the same width.

     initial_row `` is an integer indicating that
     current cursor line."""

    # obtiene el indice donde comienza y termina la tabla.
    r1, r2 = get_table_bounds(current_row_index, are_in_a_table)

    # extrae de la tabla solo las celdas de texto
    table_as_list = extract_table(vim.current.buffer, r1, r2)

    # generates a new table type restructured text and draws in the buffer.
    table_content = create_table(table_as_list)
    copy_to_buffer(vim.current.buffer, table_content, r1)


def FixTable():
    (row, col) = vim.current.window.cursor
    line = vim.current.buffer[row-1]

    if are_in_a_table(line):
        fix_table(row-1)
    else:
        print "I'm not in a table. Finishing ..."


def CreateTable():
    (row, col) = vim.current.window.cursor
    line = vim.current.buffer[row-1]

    top, bottom = get_table_bounds(row - 1, are_in_a_paragraph)
    lines = extract_words_as_lists(vim.current.buffer, top, bottom)
    table_content = create_table(lines)
    vim.current.buffer[top:bottom+1] = table_content.split('\n')


EOF

map ,,c :python CreateTable()<CR>
map ,,f :python FixTable()<CR>


endif
