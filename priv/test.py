from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import erlang
import os, struct

# import os, time
chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.add_argument("--window-size=960x540")
chrome_options.add_argument("--no-sandbox")
driver = webdriver.Chrome(chrome_options=chrome_options)

def send(term, stream):
  """Write an Erlang term to an output stream."""
  payload = erlang.term_to_binary(term)
  header = struct.pack('!I', len(payload))
  stream.write(header)
  stream.write(payload)
  stream.flush()

def recv(stream):
  """Read an Erlang term from an input stream."""
  header = stream.read(4)
  if len(header) != 4:
      return None # EOF
  (length,) = struct.unpack('!I', header)
  payload = stream.read(length)
  if len(payload) != length:
      return None
  term = erlang.binary_to_term(payload)
  return term

def recv_loop(stream):
  """Yield Erlang terms from an input stream."""
  message = recv(stream)
  while message:
      yield message
      message = recv(stream)

def handle_message(message):
  url = message.value.decode()
  print(f'url=' + url)
  driver.get(url)
  search_box = driver.find_element_by_name('q')
  search_box.submit()
  # driver.get_screenshot_as_file("capture.png")
  screenshot = erlang.OtpErlangBinary(bytes(driver.get_screenshot_as_png()))
  send(screenshot, output)
  # driver.close()

if __name__ == '__main__':
  print("hello, world\n")
  input, output = os.fdopen(3, 'rb'), os.fdopen(4, 'wb')
  for message in recv_loop(input):
      handle_message(message)