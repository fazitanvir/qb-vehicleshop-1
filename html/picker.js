const pickrContainer = document.querySelector('.pickr-container');
const themeContainer = document.querySelector('.theme-container');
const themes = [      
    [
        'nano',
        {
            name: "Primary Color",
            swatches: [
                'rgba(244, 67, 54, 1)',
                'rgba(233, 30, 99, 0.95)',
                'rgba(156, 39, 176, 0.9)',
                'rgba(103, 58, 183, 0.85)',
                'rgba(63, 81, 181, 0.8)',
                'rgba(33, 150, 243, 0.75)',
                'rgba(3, 169, 244, 0.7)'
            ],

            defaultRepresentation: 'RGBA',
            type: true,
            components: {
                preview: false,
                opacity: false,
                hue: true,
                interaction: {
                    hex: false,
                    rgba: true,
                    hsva: false,
                    input: true,
                    clear: true,
                    save: true
                }
            }
        }
    ],
    [
        'nano',
        {
            name: "Secondary Color",
            swatches: [
                'rgba(244, 67, 54, 1)',
                'rgba(233, 30, 99, 0.95)',
                'rgba(156, 39, 176, 0.9)',
                'rgba(103, 58, 183, 0.85)',
                'rgba(63, 81, 181, 0.8)',
                'rgba(33, 150, 243, 0.75)',
                'rgba(3, 169, 244, 0.7)'
            ],
            type: false,
            defaultRepresentation: 'RGBA',
            components: {
                preview: true,
                opacity: false,
                hue: true,
                interaction: {
                    hex: false,
                    rgba: true,
                    hsva: false,
                    input: true,
                    clear: true,
                    save: true
                }
            }
        }
    ]
];

const buttons = [];
let pickr = null;

for (const [theme, config] of themes) {
    const button = document.createElement('button');
    button.innerHTML = config.name;
    buttons.push(button);

    button.addEventListener('click', () => {
        const el = document.createElement('p');
        pickrContainer.appendChild(el);

        // Delete previous instance
        if (pickr) {
            pickr.destroyAndRemove();
        }

        // Apply active class
        for (const btn of buttons) {
            btn.classList[btn === button ? 'add' : 'remove']('active');
        }

        // Create fresh instance
        pickr = new Pickr(Object.assign({
            el, theme,
            default: '#42445a'
        }, config));

        // Set events
        pickr.on('init', instance => {
        //    console.log('Event: "init"', instance);
        }).on('save', (color, instance) => {
          //  console.log('Event: "save"', color, instance);
            $.post("https://qb-vehicleshop/RGBVehicle", JSON.stringify({primary: config.type, color: color.toRGBA()}));
        }).on('change', (color, source, instance) => {
          //  console.log('Event: "change"', color, source, instance);
            $.post("https://qb-vehicleshop/RGBVehicle", JSON.stringify({primary: config.type, color: color.toRGBA()}));
        })
    });

    themeContainer.appendChild(button);

    button.setAttribute("onclick","openOption()");
}

buttons[0].click();



function openOption(option){

    pickr.show();
  
}