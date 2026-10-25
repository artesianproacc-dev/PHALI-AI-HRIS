import sharp from 'sharp';
// Derive install icons from the supplied PHALI AI-HRIS logo; retain originals.
const source='public/branding/phali-symbol.png';
for(const size of [192,512])await sharp(source).resize(size,size,{fit:'contain',background:'#f4f7f6'}).flatten({background:'#f4f7f6'}).png().toFile(`public/icon-${size}.png`);
await sharp(source).resize(512,512,{fit:'contain',background:'#f4f7f6'}).flatten({background:'#f4f7f6'}).png().toFile('public/maskable-512.png');
