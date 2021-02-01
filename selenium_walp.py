ubuntu@ip-10-0-1-254:~/going_headless$ cat walp.py
import os
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
# import Action chains
from selenium.webdriver import ActionChains

chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.binary_location = '/usr/bin/google-chrome'

driver = webdriver.Chrome(executable_path=os.path.abspath("chromedriver"),   chrome_options=chrome_options)
for x in range(100):
    driver.get("http://www.brett1.com")
    #driver.get("http://badstore-wafaas.cudathon.com")
    #driver.get("http://www.python.org")
    import time
    #time.sleep(1)
    #print("Hello", "how are you?")
    #assert "BadStore" in driver.title
    #assert "Python" in driver.title
    #elem = driver.find_element_by_name("searchquery")
    #to refresh the browser
    driver.refresh()
    # identifying the source element
    #source= driver.find_element_by_xpath("//*[text()='username']");
    # action chain object creation
    action = ActionChains(driver)
    # move to the element and click then perform the operation
    elem = driver.find_element_by_name("username")
    action.move_to_element(elem).click().perform()
    elem.clear()
    elem.send_keys("miyuki")
    elem = driver.find_element_by_name("password")
    elem.clear()
    elem.send_keys("hello")
    elem.send_keys(Keys.RETURN)
    #assert "Useless" in driver.page_source
    #assert "animal" in driver.page_source
    print(driver.page_source)
driver.close()
