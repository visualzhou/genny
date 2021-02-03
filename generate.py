import jinja2


templateLoader = jinja2.FileSystemLoader(searchpath="./")
templateEnv = jinja2.Environment(loader=templateLoader, extensions=["jinja2.ext.loopcontrols"])
TEMPLATE_FILE = "template.yml.j2"
template = templateEnv.get_template(TEMPLATE_FILE)

threads = [1, 16, 32, 64, 128, 256, 512, 768, 1024]
threads = [1, 16, 64, 256, 1024, 2048]
iteration = 1
s = template.render(threads = threads, total_phase = len(threads) * iteration * 2, iteration = iteration)
print(s)
