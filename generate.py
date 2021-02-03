import jinja2


templateLoader = jinja2.FileSystemLoader(searchpath="./")
templateEnv = jinja2.Environment(loader=templateLoader, extensions=["jinja2.ext.loopcontrols"])
# TEMPLATE_FILE = "template.yml.j2"
TEMPLATE_FILE = "indexed-insert.yml.j2"
template = templateEnv.get_template(TEMPLATE_FILE)

threads = [1, 16, 32, 64, 128, 256, 512, 768, 1024]
threads = [1, 16, 64, 256, 1024, 2048]
# threads = [1]
iteration = 1
s = template.render(threads = threads, iteration = iteration)
print(s)
