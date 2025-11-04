#!/usr/bin/env python3
"""
Wayland 환경에서 선택된 텍스트의 한/영 전환
KDE Plasma (Wayland) 전용
"""

import subprocess
import sys
import time

# 영어 → 한글 자판 매핑 (2벌식)
ENG_TO_KOR = {
    'q': 'ㅂ', 'w': 'ㅈ', 'e': 'ㄷ', 'r': 'ㄱ', 't': 'ㅅ',
    'y': 'ㅛ', 'u': 'ㅕ', 'i': 'ㅑ', 'o': 'ㅐ', 'p': 'ㅔ',
    'a': 'ㅁ', 's': 'ㄴ', 'd': 'ㅇ', 'f': 'ㄹ', 'g': 'ㅎ',
    'h': 'ㅗ', 'j': 'ㅓ', 'k': 'ㅏ', 'l': 'ㅣ',
    'z': 'ㅋ', 'x': 'ㅌ', 'c': 'ㅊ', 'v': 'ㅍ', 'b': 'ㅠ',
    'n': 'ㅜ', 'm': 'ㅡ',
    'Q': 'ㅃ', 'W': 'ㅉ', 'E': 'ㄸ', 'R': 'ㄲ', 'T': 'ㅆ',
    'O': 'ㅒ', 'P': 'ㅖ',
}

# 한글 자모 분해
CHOSUNG = ['ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ']
JUNGSUNG = ['ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ']
JONGSUNG = ['', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ']

# 한글 → 영어 역매핑
KOR_TO_ENG = {v: k for k, v in ENG_TO_KOR.items()}

# 복합 자모 분해
JUNGSUNG_COMBINE = {
    'ㅘ': ['ㅗ', 'ㅏ'], 'ㅙ': ['ㅗ', 'ㅐ'], 'ㅚ': ['ㅗ', 'ㅣ'],
    'ㅝ': ['ㅜ', 'ㅓ'], 'ㅞ': ['ㅜ', 'ㅔ'], 'ㅟ': ['ㅜ', 'ㅣ'],
    'ㅢ': ['ㅡ', 'ㅣ']
}

JONGSUNG_COMBINE = {
    'ㄳ': ['ㄱ', 'ㅅ'], 'ㄵ': ['ㄴ', 'ㅈ'], 'ㄶ': ['ㄴ', 'ㅎ'],
    'ㄺ': ['ㄹ', 'ㄱ'], 'ㄻ': ['ㄹ', 'ㅁ'], 'ㄼ': ['ㄹ', 'ㅂ'],
    'ㄽ': ['ㄹ', 'ㅅ'], 'ㄾ': ['ㄹ', 'ㅌ'], 'ㄿ': ['ㄹ', 'ㅍ'],
    'ㅀ': ['ㄹ', 'ㅎ'], 'ㅄ': ['ㅂ', 'ㅅ']
}


def decompose_hangul(char):
    """한글 글자를 초성, 중성, 종성으로 분해"""
    if not ('가' <= char <= '힣'):
        return [char]

    code = ord(char) - ord('가')
    cho_idx = code // (21 * 28)
    jung_idx = (code % (21 * 28)) // 28
    jong_idx = code % 28

    result = [CHOSUNG[cho_idx]]

    # 중성 분해
    jung = JUNGSUNG[jung_idx]
    if jung in JUNGSUNG_COMBINE:
        result.extend(JUNGSUNG_COMBINE[jung])
    else:
        result.append(jung)

    # 종성 분해
    if jong_idx > 0:
        jong = JONGSUNG[jong_idx]
        if jong in JONGSUNG_COMBINE:
            result.extend(JONGSUNG_COMBINE[jong])
        else:
            result.append(jong)

    return result


def compose_hangul(jamos):
    """자모 리스트를 한글 글자로 조합"""
    if not jamos:
        return ''

    result = []
    i = 0

    while i < len(jamos):
        if jamos[i] not in CHOSUNG:
            result.append(jamos[i])
            i += 1
            continue

        cho = jamos[i]
        cho_idx = CHOSUNG.index(cho)
        i += 1

        # 중성이 없으면 자음만 추가
        if i >= len(jamos) or jamos[i] not in JUNGSUNG:
            result.append(cho)
            continue

        jung = jamos[i]
        i += 1

        # 중성 결합 시도 (ㅗ + ㅏ = ㅘ)
        if i < len(jamos) and jamos[i] in JUNGSUNG:
            combined = jung + jamos[i]
            for compound, parts in JUNGSUNG_COMBINE.items():
                if parts == [jung, jamos[i]]:
                    jung = compound
                    i += 1
                    break

        jung_idx = JUNGSUNG.index(jung)

        # 종성 확인
        jong_idx = 0
        if i < len(jamos) and jamos[i] in CHOSUNG:
            # 다음이 중성이면 종성이 아님
            if i + 1 < len(jamos) and jamos[i + 1] in JUNGSUNG:
                pass
            else:
                jong = jamos[i]
                if jong in JONGSUNG:
                    jong_idx = JONGSUNG.index(jong)
                    i += 1

                    # 종성 결합 시도 (ㄱ + ㅅ = ㄳ)
                    if i < len(jamos) and jamos[i] in CHOSUNG:
                        if i + 1 < len(jamos) and jamos[i + 1] in JUNGSUNG:
                            # 다음 글자의 초성이므로 결합 안함
                            pass
                        else:
                            combined = jong + jamos[i]
                            for compound, parts in JONGSUNG_COMBINE.items():
                                if parts == [jong, jamos[i]]:
                                    jong_idx = JONGSUNG.index(compound)
                                    i += 1
                                    break

        # 한글 조합
        code = cho_idx * 21 * 28 + jung_idx * 28 + jong_idx
        result.append(chr(code + ord('가')))

    return ''.join(result)


def eng_to_kor(text):
    """영어 타이핑을 한글로 변환"""
    jamos = [ENG_TO_KOR.get(c, c) for c in text]
    return compose_hangul(jamos)


def kor_to_eng(text):
    """한글을 영어 타이핑으로 변환"""
    result = []
    for char in text:
        if '가' <= char <= '힣':
            jamos = decompose_hangul(char)
            result.extend([KOR_TO_ENG.get(j, j) for j in jamos])
        else:
            result.append(KOR_TO_ENG.get(char, char))
    return ''.join(result)


def get_selection_wayland():
    """Wayland에서 선택된 텍스트 가져오기"""
    try:
        # wl-paste 사용 (wl-clipboard 패키지 필요)
        result = subprocess.run(
            ['wl-paste', '-p'],
            capture_output=True,
            text=True,
            timeout=1
        )
        if result.returncode == 0:
            return result.stdout
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass

    return None


def set_clipboard_wayland(text):
    """Wayland 클립보드에 텍스트 복사"""
    try:
        subprocess.run(
            ['wl-copy'],
            input=text,
            text=True,
            timeout=1
        )
        return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False

def paste_clipboard_wayland():
    """Wayland에서 클립보드 붙여넣기"""
    try:
        subprocess.run(
            ['wl-paste', '-p'],
            timeout=1,
            capture_output=True
        )
        return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False


def simulate_paste_wayland():
    """Wayland에서 Ctrl+V 붙여넣기 시뮬레이션"""
    try:
        # wtype 사용 (먼저 시도)
        result = subprocess.run(
            ['wtype', '-M', 'ctrl', 'v', '-m', 'ctrl'],
            timeout=1,
            capture_output=True
        )
        if result.returncode == 0:
            return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass

    try:
        # ydotool 사용 (대안)
        subprocess.run(
            ['ydotool', 'key', '29:1', '47:1', '47:0', '29:0'],  # Ctrl+V
            timeout=1,
            capture_output=True
        )
        return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass

    try:
        # dotool 사용 (또 다른 대안)
        subprocess.run(
            ['dotool'],
            input='keydown leftctrl\nkey v\nkeyup leftctrl\n',
            text=True,
            timeout=1,
            capture_output=True
        )
        return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass

    if paste_clipboard_wayland():
        return True

    return False


def send_notification(title, message):
    """KDE 알림 표시"""
    try:
        subprocess.run(
            ['kdialog', '--passivepopup', message, '2', '--title', title],
            timeout=1
        )
    except:
        try:
            subprocess.run(
                ['notify-send', title, message],
                timeout=1
            )
        except:
            pass


def main():
    # 선택된 텍스트 가져오기
    selected_text = get_selection_wayland()

    if not selected_text:
        send_notification('한/영 전환', '선택된 텍스트가 없습니다.')
        return

    selected_text = selected_text.strip()
    if not selected_text:
        send_notification('한/영 전환', '선택된 텍스트가 비어있습니다.')
        return

    # 한글이 포함되어 있으면 한→영, 아니면 영→한
    has_hangul = any('가' <= c <= '힣' or c in KOR_TO_ENG for c in selected_text)

    if has_hangul:
        converted = kor_to_eng(selected_text)
    else:
        converted = eng_to_kor(selected_text)

    # 클립보드에 복사
    if set_clipboard_wayland(converted):
        send_notification('한/영 전환 완료', f'{selected_text[:20]}... → {converted[:20]}...')
        print(f'변환 완료: {selected_text} → {converted}')
        simulate_paste_wayland()
    else:
        send_notification('한/영 전환 실패', 'wl-clipboard가 설치되어 있는지 확인하세요.')
        print('오류: wl-clipboard를 찾을 수 없습니다.', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
